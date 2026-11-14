/**
 * 规则引擎（编排层，纯函数）。
 * 计算流程严格对应《软件需求说明书》3.3：
 *   收集 → 求值 → 展开 → 仲裁 → 应用 → 记录
 */
import {
  Device,
  baselineDevices,
  deviceHasProperty,
  deviceProperties,
  isValidPropertyValue,
  readProperty,
  writeProperty
} from '../model/Device';
import { EnvState } from '../model/EnvState';
import { LogEntry, LogReject, LogStep, newLogId } from '../model/LogEntry';
import { Rule } from '../model/Rule';
import { evaluateRuleConditions } from './ConditionEvaluator';
import { PendingAction, rejectReason, resolveConflict, targetKeyOf } from './ConflictResolver';

export interface EvaluationResult {
  /** 按执行顺序记录的动作结果 */
  steps: LogStep[];
  /** 被拒绝的动作（仲裁落败 / 设备不存在 / 值非法） */
  rejected: LogReject[];
  /** 命中的规则 */
  matched: Rule[];
  /** 计算后的设备快照（入参 devices 不被修改） */
  nextDevices: Device[];
  /** 参与计算的启用规则数 */
  ruleCount: number;
}

/** 排序：优先级降序，同级先定义者优先 */
export function sortRules(rules: Rule[]): Rule[] {
  const list: Rule[] = rules.slice();
  list.sort((a: Rule, b: Rule) => {
    if (a.priority !== b.priority) {
      return b.priority - a.priority;
    }
    return a.createdAt - b.createdAt;
  });
  return list;
}

/** 自动复位步骤使用的伪规则 id */
export const BASELINE_RULE_ID: string = 'system-baseline';
export const BASELINE_RULE_NAME: string = '自动复位';

/** 核心入口：不产生任何副作用 */
export function evaluate(env: EnvState, rules: Rule[], devices: Device[]): EvaluationResult {
  // ① 收集：只取启用的规则
  const active: Rule[] = sortRules(rules.filter((r: Rule) => r.enabled));
  // ② 求值
  const matched: Rule[] = active.filter((r: Rule) => evaluateRuleConditions(r, env));

  // ③ 展开成候选动作
  const pending: PendingAction[] = [];
  let seq: number = 0;
  for (const rule of matched) {
    for (const action of rule.actions) {
      pending.push({ rule: rule, action: action, targetKey: targetKeyOf(action), seq: seq });
      seq++;
    }
  }

  // ④ 仲裁
  const resolved = resolveConflict(pending);

  // ④' 合法性校验：设备存在 / 属性受支持 / 值在范围内
  const rejected: LogReject[] = [];
  const applicable: PendingAction[] = [];
  const winnerByKey: Map<string, PendingAction> = new Map<string, PendingAction>();

  for (const item of pending) {
    const target: Device | undefined = devices.find((d: Device) => d.id === item.action.deviceId);
    if (target === undefined) {
      rejected.push(buildReject(item, item, '目标设备不存在'));
      continue;
    }
    const winner: PendingAction | undefined = resolved.winners.get(item.targetKey);
    if (winner === undefined) {
      rejected.push(buildReject(item, item, '未找到可执行动作'));
      continue;
    }
    if (winner.seq !== item.seq) {
      rejected.push(buildReject(item, winner, rejectReason(winner, item)));
      continue;
    }
    if (!deviceHasProperty(target.type, item.action.property)) {
      rejected.push(buildReject(item, item, '该设备不支持此属性'));
      continue;
    }
    if (!isValidPropertyValue(item.action.property, item.action.value)) {
      rejected.push(buildReject(item, item, '动作值超出合法范围'));
      continue;
    }
    applicable.push(item);
    winnerByKey.set(item.targetKey, item);
  }

  // ⑤ 应用：从基线重建，再叠加胜出动作
  // 基线保证「条件不再成立时设备自动回到关闭」，不会被上一次的开状态卡住
  const nextDevices: Device[] = baselineDevices(devices);
  for (const item of applicable) {
    const target: Device | undefined = nextDevices.find((d: Device) => d.id === item.action.deviceId);
    if (target !== undefined) {
      writeProperty(target, item.action.property, item.action.value);
    }
  }

  // ⑥ 记录：对「上一状态 → 本状态」做全量差异比对，
  //    规则造成的变更标注来源规则，其余变更标注「自动复位」
  const steps: LogStep[] = [];
  const handled: Set<string> = new Set<string>();
  let order: number = 0;

  for (const item of applicable) {
    const key: string = item.targetKey;
    if (handled.has(key)) {
      continue;
    }
    handled.add(key);
    const prev: Device | undefined = devices.find((d: Device) => d.id === item.action.deviceId);
    const next: Device | undefined = nextDevices.find((d: Device) => d.id === item.action.deviceId);
    if (prev === undefined || next === undefined) {
      continue;
    }
    const fromValue: number | boolean = readProperty(prev, item.action.property);
    const toValue: number | boolean = readProperty(next, item.action.property);
    if (fromValue === toValue) {
      continue;
    }
    order++;
    steps.push({
      order: order,
      ruleId: item.rule.id,
      ruleName: item.rule.name,
      deviceId: next.id,
      deviceName: next.name,
      property: item.action.property,
      fromValue: fromValue,
      toValue: toValue,
      status: 'applied'
    });
  }

  for (const next of nextDevices) {
    const prev: Device | undefined = devices.find((d: Device) => d.id === next.id);
    if (prev === undefined) {
      continue;
    }
    for (const prop of deviceProperties(next.type)) {
      const key: string = `${next.id}.${prop}`;
      if (handled.has(key)) {
        continue;
      }
      const fromValue: number | boolean = readProperty(prev, prop);
      const toValue: number | boolean = readProperty(next, prop);
      if (fromValue === toValue) {
        continue;
      }
      order++;
      steps.push({
        order: order,
        ruleId: BASELINE_RULE_ID,
        ruleName: BASELINE_RULE_NAME,
        deviceId: next.id,
        deviceName: next.name,
        property: prop,
        fromValue: fromValue,
        toValue: toValue,
        status: 'applied'
      });
    }
  }

  return {
    steps: steps,
    rejected: rejected,
    matched: matched,
    nextDevices: nextDevices,
    ruleCount: active.length
  };
}

function buildReject(item: PendingAction, winner: PendingAction, reason: string): LogReject {
  return {
    ruleId: item.rule.id,
    ruleName: item.rule.name,
    deviceId: item.action.deviceId,
    property: item.action.property,
    wanted: item.action.value,
    keptByRuleId: winner.rule.id,
    keptByRuleName: winner.rule.name,
    reason: reason
  };
}

/** 计算并生成一条日志，供 ViewModel 直接落盘 */
export function evaluateAndBuildLog(env: EnvState, rules: Rule[], devices: Device[]): LogEntry {
  return buildLog(env, evaluate(env, rules, devices));
}

/** 用已有计算结果组装日志（避免重复计算） */
export function buildLog(env: EnvState, result: EvaluationResult): LogEntry {
  return {
    id: newLogId(),
    ts: Date.now(),
    ruleCount: result.ruleCount,
    matchedRuleIds: result.matched.map((r: Rule) => r.id),
    matchedRuleNames: result.matched.map((r: Rule) => r.name),
    steps: result.steps,
    rejected: result.rejected,
    envSnapshot: env
  };
}
