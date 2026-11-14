/**
 * 条件求值器（纯函数层）。
 * 不依赖 Context / UI / 存储，因此可以在单元测试里直接调用。
 */
import { EnvState, MetricKey, readMetric } from '../model/EnvState';
import { Condition, Logic, Operator, Rule } from '../model/Rule';

/** 数值比较；临界值语义：严格不等号在「等于」时不成立（需求 3.4） */
export function compareNumber(current: number, op: Operator, expected: number): boolean {
  switch (op) {
    case '>':
      return current > expected;
    case '>=':
      return current >= expected;
    case '<':
      return current < expected;
    case '<=':
      return current <= expected;
    case '==':
      return current === expected;
    case '!=':
      return current !== expected;
    default:
      return false;
  }
}

/** 单个条件求值 */
export function evaluateCondition(cond: Condition, env: EnvState): boolean {
  const current: number | boolean = readMetric(env, cond.metric);

  // 布尔指标（人体存在）：只支持 == / !=
  if (typeof current === 'boolean') {
    const cur: boolean = current;
    if (typeof cond.value !== 'boolean') {
      return false;
    }
    const expected: boolean = cond.value;
    if (cond.operator === '==') {
      return cur === expected;
    }
    if (cond.operator === '!=') {
      return cur !== expected;
    }
    return false;
  }

  // 数值指标
  if (typeof cond.value !== 'number') {
    return false;
  }
  return compareNumber(current, cond.operator, cond.value);
}

/** 规则条件组合求值：AND 全真为真，OR 一真为真 */
export function evaluateRuleConditions(rule: Rule, env: EnvState): boolean {
  if (rule.conditions.length === 0) {
    return false;
  }
  if (rule.logic === 'OR') {
    for (const cond of rule.conditions) {
      if (evaluateCondition(cond, env)) {
        return true;
      }
    }
    return false;
  }
  for (const cond of rule.conditions) {
    if (!evaluateCondition(cond, env)) {
      return false;
    }
  }
  return true;
}

/** 便捷构造：仅用于测试与内置示例 */
export function makeCondition(metric: MetricKey, op: Operator, value: number | boolean): Condition {
  return { metric: metric, operator: op, value: value };
}

/** 条件组合逻辑的展示名 */
export function logicLabel(logic: Logic): string {
  return logic === 'AND' ? '同时满足' : '满足任一';
}
