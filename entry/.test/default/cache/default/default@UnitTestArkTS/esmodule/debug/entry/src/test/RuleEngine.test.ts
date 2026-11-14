import { describe, it, expect } from "@normalized:N&&&@ohos/hypium/index&1.0.21";
import { readProperty, defaultDevices } from "@normalized:N&&&entry/src/main/ets/model/Device&";
import type { Device } from "@normalized:N&&&entry/src/main/ets/model/Device&";
import { clampEnv, defaultEnv } from "@normalized:N&&&entry/src/main/ets/model/EnvState&";
import type { EnvState } from "@normalized:N&&&entry/src/main/ets/model/EnvState&";
import { validateRule } from "@normalized:N&&&entry/src/main/ets/model/Rule&";
import type { Action, Condition, Rule } from "@normalized:N&&&entry/src/main/ets/model/Rule&";
import { evaluate, sortRules } from "@normalized:N&&&entry/src/main/ets/engine/RuleEngine&";
/** 构造一条测试用规则 */
function makeRule(id: string, priority: number, createdAt: number, conds: Condition[], acts: Action[], enabled: boolean = true): Rule {
    return {
        id: id,
        name: `规则-${id}`,
        enabled: enabled,
        priority: priority,
        logic: 'AND',
        conditions: conds,
        actions: acts,
        createdAt: createdAt
    };
}
function env(temperature: number, illuminance: number, humidity: number, presence: boolean): EnvState {
    return { temperature: temperature, illuminance: illuminance, humidity: humidity, presence: presence };
}
/** 空调设定温度 */
function acTemp(devices: Device[]): number {
    const ac: Device = devices.find((d: Device) => d.id === 'ac') as Device;
    return readProperty(ac, 'targetTemp') as number;
}
/** 空调开关 */
function acPower(devices: Device[]): boolean {
    const ac: Device = devices.find((d: Device) => d.id === 'ac') as Device;
    return readProperty(ac, 'power') as boolean;
}
export default function ruleEngineTest() {
    describe('RuleEngine', () => {
        // T-01 正常：单条件命中
        it('T01_single_condition_hit', 0, () => {
            const rules: Rule[] = [
                makeRule('r1', 5, 1000, [{ metric: 'temperature', operator: '>', value: 28 }], [{ deviceId: 'ac', property: 'power', value: true }])
            ];
            const result = evaluate(env(30, 500, 50, true), rules, defaultDevices());
            expect(result.matched.length).assertEqual(1);
            expect(result.steps.length).assertEqual(1);
            expect(result.steps[0].status).assertEqual('applied');
            expect(acPower(result.nextDevices)).assertTrue();
        });
        // T-02 正常：双条件 AND 命中
        it('T02_and_condition_hit', 0, () => {
            const rules: Rule[] = [
                makeRule('r2', 6, 1000, [
                    { metric: 'temperature', operator: '>', value: 28 },
                    { metric: 'presence', operator: '==', value: true }
                ], [{ deviceId: 'ac', property: 'power', value: true }])
            ];
            const result = evaluate(env(30, 500, 50, true), rules, defaultDevices());
            expect(result.matched.length).assertEqual(1);
            expect(acPower(result.nextDevices)).assertTrue();
        });
        // T-03 正常：AND 缺一不命中
        it('T03_and_missing_one_not_hit', 0, () => {
            const rules: Rule[] = [
                makeRule('r3', 6, 1000, [
                    { metric: 'temperature', operator: '>', value: 28 },
                    { metric: 'presence', operator: '==', value: true }
                ], [{ deviceId: 'ac', property: 'power', value: true }])
            ];
            const result = evaluate(env(30, 500, 50, false), rules, defaultDevices());
            expect(result.matched.length).assertEqual(0);
            expect(result.steps.length).assertEqual(0);
            expect(acPower(result.nextDevices)).assertFalse();
        });
        // T-04 边界：等于临界值不触发
        it('T04_boundary_equal_not_triggered', 0, () => {
            const rules: Rule[] = [
                makeRule('r4', 5, 1000, [{ metric: 'temperature', operator: '>', value: 28 }], [{ deviceId: 'ac', property: 'power', value: true }])
            ];
            const result = evaluate(env(28, 500, 50, true), rules, defaultDevices());
            expect(result.matched.length).assertEqual(0);
        });
        // T-05 边界：刚过临界值触发
        it('T05_boundary_just_over_triggered', 0, () => {
            const rules: Rule[] = [
                makeRule('r5', 5, 1000, [{ metric: 'temperature', operator: '>', value: 28 }], [{ deviceId: 'ac', property: 'power', value: true }])
            ];
            const result = evaluate(env(28.1, 500, 50, true), rules, defaultDevices());
            expect(result.matched.length).assertEqual(1);
        });
        // T-06 正常：冲突按优先级仲裁
        it('T06_conflict_priority_arbitration', 0, () => {
            const high: Rule = makeRule('hi', 10, 1000, [{ metric: 'temperature', operator: '>', value: 28 }], [{ deviceId: 'ac', property: 'targetTemp', value: 24 }]);
            const low: Rule = makeRule('lo', 3, 2000, [{ metric: 'temperature', operator: '>', value: 20 }], [{ deviceId: 'ac', property: 'targetTemp', value: 26 }]);
            const result = evaluate(env(30, 500, 50, true), [low, high], defaultDevices());
            expect(result.matched.length).assertEqual(2);
            expect(acTemp(result.nextDevices)).assertEqual(24);
            expect(result.rejected.length).assertEqual(1);
            expect(result.rejected[0].ruleId).assertEqual('lo');
            expect(result.rejected[0].keptByRuleId).assertEqual('hi');
        });
        // T-07 正常：停用规则不参与
        it('T07_disabled_rule_ignored', 0, () => {
            const rules: Rule[] = [
                makeRule('r7', 9, 1000, [{ metric: 'temperature', operator: '>', value: 10 }], [{ deviceId: 'ac', property: 'power', value: true }], false)
            ];
            const result = evaluate(env(30, 500, 50, true), rules, defaultDevices());
            expect(result.ruleCount).assertEqual(0);
            expect(result.steps.length).assertEqual(0);
            expect(acPower(result.nextDevices)).assertFalse();
        });
        // T-08 异常：越界输入被钳制
        it('T08_out_of_range_clamped', 0, () => {
            const clamped: EnvState = clampEnv(env(30, 9999, 150, true));
            expect(clamped.humidity).assertEqual(100);
            expect(clamped.illuminance).assertEqual(2000);
        });
        // T-09 异常：空条件规则校验失败
        it('T09_empty_conditions_rejected', 0, () => {
            const bad: Rule = makeRule('bad', 5, 1000, [], [{ deviceId: 'ac', property: 'power', value: true }]);
            expect(validateRule(bad).length > 0).assertTrue();
            const result = evaluate(defaultEnv(), [bad], defaultDevices());
            expect(result.matched.length).assertEqual(0);
        });
        // T-10 正常：数据往返（持久化前的序列化校验）
        it('T10_serialize_roundtrip', 0, () => {
            const rules: Rule[] = [
                makeRule('r10', 7, 1000, [{ metric: 'illuminance', operator: '<', value: 200 }], [{ deviceId: 'light', property: 'power', value: true },
                    { deviceId: 'light', property: 'brightness', value: 70 }])
            ];
            const text: string = JSON.stringify(rules);
            const restored: Rule[] = JSON.parse(text) as Rule[];
            expect(restored.length).assertEqual(1);
            expect(restored[0].actions.length).assertEqual(2);
            expect(restored[0].conditions[0].value as number).assertEqual(200);
            const result = evaluate(env(25, 100, 50, true), restored, defaultDevices());
            expect(result.matched.length).assertEqual(1);
            expect(result.steps.length).assertEqual(2);
        });
        // 附加：排序契约（优先级降序、同级先定义者优先）
        it('T11_sort_rules_contract', 0, () => {
            const a: Rule = makeRule('a', 3, 2000, [], []);
            const b: Rule = makeRule('b', 9, 3000, [], []);
            const c: Rule = makeRule('c', 9, 1000, [], []);
            const sorted: Rule[] = sortRules([a, b, c]);
            expect(sorted[0].id).assertEqual('c');
            expect(sorted[1].id).assertEqual('b');
            expect(sorted[2].id).assertEqual('a');
        });
    });
}
