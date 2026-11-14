/**
 * 出厂示例数据：首次启动时写入，同时也是「恢复出厂设置」的恢复目标。
 *
 * 规则设计原则（与引擎的「基线重算」语义配套）：
 *   1. 引擎每轮都从设备基线（全关）出发，只叠加命中规则的动作；
 *   2. 所以规则只需要描述「什么时候该打开/设置成什么」，
 *      条件不再成立时设备会自动回到基线，不需要为每个反向情况再写一条"关闭"规则；
 *   3. 例外是「冲突演示」：R4 故意与 R1 争抢空调开关，用于展示优先级仲裁。
 */
import { Rule } from './Rule';

export function defaultRules(): Rule[] {
  return [
    {
      id: 'sample-r1',
      name: '高温开空调',
      enabled: true,
      priority: 8,
      logic: 'AND',
      conditions: [
        { metric: 'temperature', operator: '>', value: 28 },
        { metric: 'presence', operator: '==', value: true }
      ],
      actions: [
        { deviceId: 'ac', property: 'power', value: true },
        { deviceId: 'ac', property: 'targetTemp', value: 24 }
      ],
      createdAt: 1730000001000
    },
    {
      id: 'sample-r2',
      name: '天黑开灯',
      enabled: true,
      priority: 6,
      logic: 'AND',
      conditions: [
        { metric: 'illuminance', operator: '<', value: 200 },
        { metric: 'presence', operator: '==', value: true }
      ],
      actions: [
        { deviceId: 'light', property: 'power', value: true },
        { deviceId: 'light', property: 'brightness', value: 70 }
      ],
      createdAt: 1730000002000
    },
    {
      id: 'sample-r3',
      name: '潮湿开风扇',
      enabled: true,
      priority: 5,
      logic: 'AND',
      conditions: [{ metric: 'humidity', operator: '>', value: 70 }],
      actions: [
        { deviceId: 'fan', property: 'power', value: true },
        { deviceId: 'fan', property: 'speed', value: 2 }
      ],
      createdAt: 1730000003000
    },
    {
      id: 'sample-r5',
      name: '白天拉开窗帘',
      enabled: true,
      priority: 5,
      logic: 'AND',
      conditions: [{ metric: 'illuminance', operator: '>', value: 800 }],
      actions: [{ deviceId: 'curtain', property: 'openness', value: 80 }],
      createdAt: 1730000005000
    },
    {
      id: 'sample-r4',
      name: '白天省电关空调',
      enabled: true,
      priority: 4,
      logic: 'AND',
      conditions: [
        { metric: 'illuminance', operator: '>', value: 500 },
        { metric: 'presence', operator: '==', value: true }
      ],
      actions: [{ deviceId: 'ac', property: 'power', value: false }],
      createdAt: 1730000004000
    }
  ];
}
