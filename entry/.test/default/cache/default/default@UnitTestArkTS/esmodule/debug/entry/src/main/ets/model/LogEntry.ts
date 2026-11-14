import type { DeviceProperty } from './Device';
import type { EnvState } from './EnvState';
/** 单个动作的执行结果 */
export type StepStatus = 'applied' | 'skipped' | 'rejected';
export interface LogStep {
    /** 执行顺序，从 1 开始 */
    order: number;
    ruleId: string;
    ruleName: string;
    deviceId: string;
    deviceName: string;
    property: DeviceProperty;
    fromValue: number | boolean;
    toValue: number | boolean;
    status: StepStatus;
}
/** 被仲裁拒绝的动作 */
export interface LogReject {
    ruleId: string;
    ruleName: string;
    deviceId: string;
    property: DeviceProperty;
    wanted: number | boolean;
    /** 胜出规则，用于说明「被谁覆盖」 */
    keptByRuleId: string;
    keptByRuleName: string;
    reason: string;
}
export interface LogEntry {
    id: string;
    ts: number;
    /** 参与本次计算的规则条数 */
    ruleCount: number;
    matchedRuleIds: string[];
    matchedRuleNames: string[];
    steps: LogStep[];
    rejected: LogReject[];
    envSnapshot: EnvState;
}
export function newLogId(): string {
    const rand: number = Math.floor(Math.random() * 100000);
    return `log-${Date.now()}-${rand}`;
}
/** 日志摘要文案，用于列表单行展示 */
export function logSummary(entry: LogEntry): string {
    const applied: number = entry.steps.filter((s: LogStep) => s.status === 'applied').length;
    if (entry.matchedRuleIds.length === 0) {
        return '无规则命中';
    }
    return `命中 ${entry.matchedRuleIds.length} 条规则，执行 ${applied} 个动作，拒绝 ${entry.rejected.length} 个`;
}
/** 时间戳格式化为 HH:mm:ss */
export function formatTime(ts: number): string {
    const d: Date = new Date(ts);
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mm: string = d.getMinutes().toString().padStart(2, '0');
    const ss: string = d.getSeconds().toString().padStart(2, '0');
    return `${hh}:${mm}:${ss}`;
}
