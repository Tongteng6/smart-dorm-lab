/**
 * 规则引擎（编排层，纯函数）。
 * 计算流程严格对应《软件需求说明书》3.3：
 *   收集 → 求值 → 展开 → 仲裁 → 应用 → 记录
 */
import {
  Device,
  cloneDevices,
  deviceHasProperty,
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

  // ⑤ 应用 + ⑥ 记录
  const nextDevices: Device[] = cloneDevices(devices);
  const steps: LogStep[] = [];
  const rejected: LogReject[] = [];
  let order: number = 0;

  for (const item of pending) {
    const target: Device | undefined = nextDevices.find((d: Device) => d.id === item.action.deviceId);

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
      // 仲裁落败
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

    const fromValue: number | boolean = readProperty(target, item.action.property);
    const changed: boolean = writeProperty(target, item.action.property, item.action.value);
    order++;
    steps.push({
      order: order,
      ruleId: item.rule.id,
      ruleName: item.rule.name,
      deviceId: target.id,
      deviceName: target.name,
      property: item.action.property,
      fromValue: fromValue,
      toValue: item.action.value,
      status: changed ? 'applied' : 'skipped'
    });
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
  const result: EvaluationResult = evaluate(env, rules, devices);
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
