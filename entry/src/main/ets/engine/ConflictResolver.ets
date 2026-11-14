/**
 * 冲突仲裁：多条规则想修改同一设备属性时，谁说了算。
 * 规则（需求 3.3 第 4 步）：
 *   1. 优先级高者胜；
 *   2. 优先级相同，先定义（createdAt 更早）者胜；
 *   3. 落败动作不执行，但必须留下拒绝记录。
 */
import { Action, Rule } from '../model/Rule';

/** 一个待执行的候选动作 */
export interface PendingAction {
  rule: Rule;
  action: Action;
  /** deviceId + '.' + property */
  targetKey: string;
  /** 在候选列表中的原始序号，用于最终排序稳定 */
  seq: number;
}

export interface ResolveResult {
  /** targetKey -> 胜出动作 */
  winners: Map<string, PendingAction>;
  /** 被仲裁拒绝的动作 */
  rejected: PendingAction[];
}

export function targetKeyOf(action: Action): string {
  return `${action.deviceId}.${action.property}`;
}

/** a 是否比 b 更有资格胜出 */
export function isStronger(a: PendingAction, b: PendingAction): boolean {
  if (a.rule.priority !== b.rule.priority) {
    return a.rule.priority > b.rule.priority;
  }
  if (a.rule.createdAt !== b.rule.createdAt) {
    return a.rule.createdAt < b.rule.createdAt;
  }
  return a.seq < b.seq;
}

/**
 * 对候选动作按目标属性分组仲裁。
 * 入参顺序即执行顺序（已按优先级降序、创建时间升序排好）。
 */
export function resolveConflict(pending: PendingAction[]): ResolveResult {
  const winners: Map<string, PendingAction> = new Map<string, PendingAction>();
  const rejected: PendingAction[] = [];

  for (const item of pending) {
    const current: PendingAction | undefined = winners.get(item.targetKey);
    if (current === undefined) {
      winners.set(item.targetKey, item);
      continue;
    }
    if (isStronger(item, current)) {
      // 后来者更强，原胜出者降级为被拒
      rejected.push(current);
      winners.set(item.targetKey, item);
    } else {
      rejected.push(item);
    }
  }

  return { winners: winners, rejected: rejected };
}

/** 被拒绝动作的原因文案 */
export function rejectReason(winner: PendingAction, loser: PendingAction): string {
  if (winner.rule.priority !== loser.rule.priority) {
    return `优先级较低（${loser.rule.priority} < ${winner.rule.priority}），被「${winner.rule.name}」覆盖`;
  }
  return `优先级相同但定义更晚，被「${winner.rule.name}」覆盖`;
}
