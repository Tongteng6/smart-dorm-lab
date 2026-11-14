import { metricLabel, metricUnit } from "@normalized:N&&&entry/src/main/ets/model/EnvState&";
import type { MetricKey } from "@normalized:N&&&entry/src/main/ets/model/EnvState&";
import { isNumberProperty, propertyLabel } from "@normalized:N&&&entry/src/main/ets/model/Device&";
import type { DeviceProperty } from "@normalized:N&&&entry/src/main/ets/model/Device&";
export type Operator = '>' | '>=' | '<' | '<=' | '==' | '!=';
export type Logic = 'AND' | 'OR';
export interface Condition {
    metric: MetricKey;
    operator: Operator;
    value: number | boolean;
}
export interface Action {
    deviceId: string;
    property: DeviceProperty;
    value: number | boolean;
}
export interface Rule {
    id: string;
    name: string;
    enabled: boolean;
    /** 1-10，越大越优先 */
    priority: number;
    logic: Logic;
    conditions: Condition[];
    actions: Action[];
    createdAt: number;
}
/** 条件的可读文本，如「温度 > 28°C」 */
export function conditionText(cond: Condition): string {
    if (cond.metric === 'presence') {
        const on: boolean = cond.value === true;
        return on ? '有人在房间' : '无人在房间';
    }
    const unit: string = metricUnit(cond.metric);
    return `${metricLabel(cond.metric)} ${cond.operator} ${cond.value}${unit}`;
}
/** 动作的可读文本，如「空调 开关 → 开」 */
export function actionText(action: Action, deviceName: string): string {
    if (action.property === 'power') {
        const on: boolean = action.value === true;
        return `${deviceName} 开关 → ${on ? '开' : '关'}`;
    }
    return `${deviceName} ${propertyLabel(action.property)} → ${action.value}`;
}
/** 整条规则的摘要，用于列表展示 */
export function ruleSummary(rule: Rule): string {
    const joiner: string = rule.logic === 'AND' ? ' 且 ' : ' 或 ';
    return rule.conditions.map((c: Condition) => conditionText(c)).join(joiner);
}
/** 条件是否合法：类型必须与指标匹配，数值必须有限 */
export function isValidCondition(cond: Condition): boolean {
    const numericMetric: boolean = cond.metric !== 'presence';
    if (numericMetric) {
        if (typeof cond.value !== 'number' || Number.isNaN(cond.value)) {
            return false;
        }
    }
    else {
        if (typeof cond.value !== 'boolean') {
            return false;
        }
        // 布尔指标只支持相等/不等比较
        if (cond.operator !== '==' && cond.operator !== '!=') {
            return false;
        }
    }
    return true;
}
/** 保存前的整体校验，返回错误文案，空数组表示通过 */
export function validateRule(rule: Rule): string[] {
    const errors: string[] = [];
    if (rule.name.trim().length === 0) {
        errors.push('规则名称不能为空');
    }
    if (rule.conditions.length === 0) {
        errors.push('至少需要一个条件');
    }
    if (rule.actions.length === 0) {
        errors.push('至少需要一个动作');
    }
    if (rule.priority < 1 || rule.priority > 10) {
        errors.push('优先级需在 1-10 之间');
    }
    for (const cond of rule.conditions) {
        if (!isValidCondition(cond)) {
            errors.push(`条件「${conditionText(cond)}」不合法`);
        }
    }
    for (const action of rule.actions) {
        if (!isNumberProperty(action.property) && typeof action.value !== 'boolean') {
            errors.push('开关属性只接受开/关两种值');
        }
    }
    return errors;
}
/** 生成规则 id（时间戳 + 随机后缀） */
export function newRuleId(): string {
    const rand: number = Math.floor(Math.random() * 100000);
    return `rule-${Date.now()}-${rand}`;
}
