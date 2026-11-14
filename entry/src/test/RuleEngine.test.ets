import { describe, it, expect } from '@ohos/hypium';
import { Device, readProperty, defaultDevices } from '../main/ets/model/Device';
import { EnvState, clampEnv, defaultEnv } from '../main/ets/model/EnvState';
import { Action, Condition, Rule, validateRule } from '../main/ets/model/Rule';
import { evaluate, sortRules } from '../main/ets/engine/RuleEngine';
import { defaultRules } from '../main/ets/model/Samples';

/** 构造一条测试用规则 */
function makeRule(id: string, priority: number, createdAt: number, conds: Condition[],
  acts: Action[], enabled: boolean = true): Rule {
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

/** 顶灯开关 */
function lightPower(devices: Device[]): boolean {
  const light: Device = devices.find((d: Device) => d.id === 'light') as Device;
  return readProperty(light, 'power') as boolean;
}

/** 窗帘开合度 */
function curtainOpenness(devices: Device[]): number {
  const curtain: Device = devices.find((d: Device) => d.id === 'curtain') as Device;
  return readProperty(curtain, 'openness') as number;
}

/** 风扇开关 */
function fanPower(devices: Device[]): boolean {
  const fan: Device = devices.find((d: Device) => d.id === 'fan') as Device;
  return readProperty(fan, 'power') as boolean;
}

export default function ruleEngineTest() {
  describe('RuleEngine', () => {

    // T-01 正常：单条件命中
    it('T01_single_condition_hit', 0, () => {
      const rules: Rule[] = [
        makeRule('r1', 5, 1000,
          [{ metric: 'temperature', operator: '>', value: 28 }],
          [{ deviceId: 'ac', property: 'power', value: true }])
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
        makeRule('r2', 6, 1000,
          [
            { metric: 'temperature', operator: '>', value: 28 },
            { metric: 'presence', operator: '==', value: true }
          ],
          [{ deviceId: 'ac', property: 'power', value: true }])
      ];
      const result = evaluate(env(30, 500, 50, true), rules, defaultDevices());
      expect(result.matched.length).assertEqual(1);
      expect(acPower(result.nextDevices)).assertTrue();
    });

    // T-03 正常：AND 缺一不命中
    it('T03_and_missing_one_not_hit', 0, () => {
      const rules: Rule[] = [
        makeRule('r3', 6, 1000,
          [
            { metric: 'temperature', operator: '>', value: 28 },
            { metric: 'presence', operator: '==', value: true }
          ],
          [{ deviceId: 'ac', property: 'power', value: true }])
      ];
      const result = evaluate(env(30, 500, 50, false), rules, defaultDevices());
      expect(result.matched.length).assertEqual(0);
      expect(result.steps.length).assertEqual(0);
      expect(acPower(result.nextDevices)).assertFalse();
    });

    // T-04 边界：等于临界值不触发
    it('T04_boundary_equal_not_triggered', 0, () => {
      const rules: Rule[] = [
        makeRule('r4', 5, 1000,
          [{ metric: 'temperature', operator: '>', value: 28 }],
          [{ deviceId: 'ac', property: 'power', value: true }])
      ];
      const result = evaluate(env(28, 500, 50, true), rules, defaultDevices());
      expect(result.matched.length).assertEqual(0);
    });

    // T-05 边界：刚过临界值触发
    it('T05_boundary_just_over_triggered', 0, () => {
      const rules: Rule[] = [
        makeRule('r5', 5, 1000,
          [{ metric: 'temperature', operator: '>', value: 28 }],
          [{ deviceId: 'ac', property: 'power', value: true }])
      ];
      const result = evaluate(env(28.1, 500, 50, true), rules, defaultDevices());
      expect(result.matched.length).assertEqual(1);
    });

    // T-06 正常：冲突按优先级仲裁
    it('T06_conflict_priority_arbitration', 0, () => {
      const high: Rule = makeRule('hi', 10, 1000,
        [{ metric: 'temperature', operator: '>', value: 28 }],
        [{ deviceId: 'ac', property: 'targetTemp', value: 24 }]);
      const low: Rule = makeRule('lo', 3, 2000,
        [{ metric: 'temperature', operator: '>', value: 20 }],
        [{ deviceId: 'ac', property: 'targetTemp', value: 26 }]);

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
        makeRule('r7', 9, 1000,
          [{ metric: 'temperature', operator: '>', value: 10 }],
          [{ deviceId: 'ac', property: 'power', value: true }], false)
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
      const bad: Rule = makeRule('bad', 5, 1000, [],
        [{ deviceId: 'ac', property: 'power', value: true }]);
      expect(validateRule(bad).length > 0).assertTrue();
      const result = evaluate(defaultEnv(), [bad], defaultDevices());
      expect(result.matched.length).assertEqual(0);
    });

    // T-10 正常：数据往返（持久化前的序列化校验）
    it('T10_serialize_roundtrip', 0, () => {
      const rules: Rule[] = [
        makeRule('r10', 7, 1000,
          [{ metric: 'illuminance', operator: '<', value: 200 }],
          [{ deviceId: 'light', property: 'power', value: true },
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

    // T-12 回归：出厂规则下「有人 30℃ 开空调」→「变成无人后空调应关闭」
    // 规则引擎只执行命中动作、不会自动复位设备，因此必须存在显式的关机规则
    it('T12_sample_rules_turn_off_ac_when_empty', 0, () => {
      const rules: Rule[] = defaultRules();

      // 第一步：有人在房间、温度 30℃ → R1 命中，空调开
      const onResult = evaluate(env(30, 500, 50, true), rules, defaultDevices());
      expect(acPower(onResult.nextDevices)).assertTrue();

      // 第二步：人离开（温度仍是 30℃）→ 无规则命中，空调回到基线（关闭）
      const offResult = evaluate(env(30, 500, 50, false), rules, onResult.nextDevices);
      expect(acPower(offResult.nextDevices)).assertFalse();
    });

    // T-13 回归：条件不再成立时设备必须回到基线（光照 150 开灯 → 拉到 900 必须关灯）
    it('T13_device_back_to_baseline_when_condition_lost', 0, () => {
      const rules: Rule[] = defaultRules();

      // 暗环境、有人 → 开灯
      const dark = evaluate(env(25, 150, 50, true), rules, defaultDevices());
      expect(lightPower(dark.nextDevices)).assertTrue();
      expect(curtainOpenness(dark.nextDevices)).assertEqual(0);

      // 拉到明亮 → 关灯（自动复位），同时窗帘被 R5 拉开到 80%
      const bright = evaluate(env(25, 900, 50, true), rules, dark.nextDevices);
      expect(lightPower(bright.nextDevices)).assertFalse();
      expect(curtainOpenness(bright.nextDevices)).assertEqual(80);
    });

    // T-14 回归：湿度回落时风扇必须自动停
    it('T14_fan_auto_off_when_humidity_drops', 0, () => {
      const rules: Rule[] = defaultRules();

      const wet = evaluate(env(25, 500, 80, true), rules, defaultDevices());
      expect(fanPower(wet.nextDevices)).assertTrue();

      const dry = evaluate(env(25, 500, 50, true), rules, wet.nextDevices);
      expect(fanPower(dry.nextDevices)).assertFalse();
    });
  });
}
