/**
 * 出厂示例数据：首次启动时写入，同时也是「重置」的恢复目标。
 * 5 条规则中：
 *   - R1 由两个条件共同决定（温度 > 28 且有人）
 *   - R5 与 R1 争抢「空调开关」，构成一个真实的优先级冲突场景
 */
import { Rule } from './Rule';

export function defaultRules(): Rule[] {
  return [
    {
      id: 'sample-r4',
      name: '人走关设备',
      enabled: true,
      priority: 9,
      logic: 'AND',
      conditions: [{ metric: 'presence', operator: '==', value: false }],
      actions: [
        { deviceId: 'light', property: 'power', value: false },
        { deviceId: 'fan', property: 'power', value: false }
      ],
      createdAt: 1730000004000
    },
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
      name: '白天省电关空调',
      enabled: true,
      priority: 4,
      logic: 'AND',
      conditions: [{ metric: 'illuminance', operator: '>', value: 500 }],
      actions: [{ deviceId: 'ac', property: 'power', value: false }],
      createdAt: 1730000005000
    }
  ];
}
