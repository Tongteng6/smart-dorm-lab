import { router } from '@kit.ArkUI';
import { Device, DeviceProperty } from '../model/Device';
import { MetricKey, metricLabel, metricUnit } from '../model/EnvState';
import { Action, Condition, Logic, Operator, Rule, isValidCondition, newRuleId, validateRule } from '../model/Rule';
import { DormStore } from '../viewmodel/DormStore';

@Entry
@Component
struct RuleEditPage {
  @State editingId: string = '';
  @State createdAt: number = 0;
  @State ruleName: string = '';
  @State priority: number = 5;
  @State ruleEnabled: boolean = true;
  @State logic: Logic = 'AND';

  @State useCond2: boolean = false;
  @State metric1: MetricKey = 'temperature';
  @State op1: Operator = '>';
  @State num1: number = 28;
  @State flag1: boolean = true;
  @State metric2: MetricKey = 'presence';
  @State op2: Operator = '==';
  @State num2: number = 0;
  @State flag2: boolean = true;

  @State useAct2: boolean = false;
  @State dev1: string = 'ac';
  @State prop1: DeviceProperty = 'power';
  @State actNum1: number = 24;
  @State actFlag1: boolean = true;
  @State dev2: string = 'ac';
  @State prop2: DeviceProperty = 'targetTemp';
  @State actNum2: number = 24;
  @State actFlag2: boolean = true;

  @State deviceList: Device[] = [];
  @State errorText: string = '';

  aboutToAppear(): void {
    this.deviceList = DormStore.get().devices;
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params !== null && params.ruleId !== undefined) {
      this.editingId = params.ruleId;
      this.loadRule(params.ruleId);
    }
  }

  private loadRule(id: string): void {
    const found: Rule | undefined = DormStore.get().rules.find((r: Rule) => r.id === id);
    if (found === undefined) {
      return;
    }
    this.createdAt = found.createdAt;
    this.ruleName = found.name;
    this.priority = found.priority;
    this.ruleEnabled = found.enabled;
    this.logic = found.logic;

    const c1: Condition = found.conditions[0];
    if (c1 !== undefined) {
      this.metric1 = c1.metric;
      this.op1 = c1.operator;
      if (typeof c1.value === 'boolean') {
        this.flag1 = c1.value;
      } else {
        this.num1 = c1.value;
      }
    }
    if (found.conditions.length > 1) {
      this.useCond2 = true;
      const c2: Condition = found.conditions[1];
      this.metric2 = c2.metric;
      this.op2 = c2.operator;
      if (typeof c2.value === 'boolean') {
        this.flag2 = c2.value;
      } else {
        this.num2 = c2.value;
      }
    }

    const a1: Action = found.actions[0];
    if (a1 !== undefined) {
      this.dev1 = a1.deviceId;
      this.prop1 = a1.property;
      if (typeof a1.value === 'boolean') {
        this.actFlag1 = a1.value;
      } else {
        this.actNum1 = a1.value;
      }
    }
    if (found.actions.length > 1) {
      this.useAct2 = true;
      const a2: Action = found.actions[1];
      this.dev2 = a2.deviceId;
      this.prop2 = a2.property;
      if (typeof a2.value === 'boolean') {
        this.actFlag2 = a2.value;
      } else {
        this.actNum2 = a2.value;
      }
    }
  }

  private metricOptions(): SelectOption[] {
    return [
      { value: metricLabel('temperature') },
      { value: metricLabel('illuminance') },
      { value: metricLabel('humidity') },
      { value: metricLabel('presence') }
    ];
  }

  private opOptions(): SelectOption[] {
    return [
      { value: '>' }, { value: '>=' }, { value: '<' }, { value: '<=' },
      { value: '==' }, { value: '!=' }
    ];
  }

  private deviceOptions(): SelectOption[] {
    return this.deviceList.map((d: Device) => {
      const opt: SelectOption = { value: d.name };
      return opt;
    });
  }

  private propertiesOf(deviceId: string): DeviceProperty[] {
    if (deviceId === 'light') {
      return ['power', 'brightness'];
    }
    if (deviceId === 'ac') {
      return ['power', 'targetTemp'];
    }
    if (deviceId === 'fan') {
      return ['power', 'speed'];
    }
    return ['openness'];
  }

  private propLabel(p: DeviceProperty): string {
    if (p === 'power') {
      return '开关';
    }
    if (p === 'brightness') {
      return '亮度';
    }
    if (p === 'targetTemp') {
      return '设定温度';
    }
    if (p === 'openness') {
      return '开合度';
    }
    return '档位';
  }

  private propOptions(deviceId: string): SelectOption[] {
    return this.propertiesOf(deviceId).map((p: DeviceProperty) => {
      const opt: SelectOption = { value: this.propLabel(p) };
      return opt;
    });
  }

  private metricRange(metric: MetricKey): number[] {
    if (metric === 'temperature') {
      return [10, 40, 0.5];
    }
    if (metric === 'illuminance') {
      return [0, 2000, 10];
    }
    if (metric === 'humidity') {
      return [0, 100, 1];
    }
    return [0, 0, 1];
  }

  private actionRange(prop: DeviceProperty): number[] {
    if (prop === 'brightness') {
      return [0, 100, 1];
    }
    if (prop === 'targetTemp') {
      return [16, 30, 1];
    }
    if (prop === 'openness') {
      return [0, 100, 1];
    }
    if (prop === 'speed') {
      return [1, 3, 1];
    }
    return [0, 0, 1];
  }

  private actionUnit(p: DeviceProperty): string {
    if (p === 'brightness') {
      return '%';
    }
    if (p === 'targetTemp') {
      return '°C';
    }
    if (p === 'openness') {
      return '%';
    }
    return ' 档';
  }

  private buildCondition(metric: MetricKey, op: Operator, num: number, flag: boolean): Condition {
    if (metric === 'presence') {
      return { metric: metric, operator: op, value: flag };
    }
    return { metric: metric, operator: op, value: num };
  }

  private buildAction(deviceId: string, prop: DeviceProperty, num: number, flag: boolean): Action {
    if (prop === 'power') {
      return { deviceId: deviceId, property: prop, value: flag };
    }
    return { deviceId: deviceId, property: prop, value: num };
  }

  private metricIndex(index: number): number {
    const metrics: MetricKey[] = ['temperature', 'illuminance', 'humidity', 'presence'];
    return metrics.indexOf(index === 1 ? this.metric1 : this.metric2);
  }

  private opIndex(index: number): number {
    const ops: Operator[] = ['>', '>=', '<', '<=', '==', '!='];
    return ops.indexOf(index === 1 ? this.op1 : this.op2);
  }

  private deviceIndex(index: number): number {
    const id: string = index === 1 ? this.dev1 : this.dev2;
    return this.deviceList.findIndex((d: Device) => d.id === id);
  }

  private deviceName(id: string): string {
    const found: Device | undefined = this.deviceList.find((d: Device) => d.id === id);
    return found === undefined ? '设备' : found.name;
  }

  private propIndex(index: number): number {
    const props: DeviceProperty[] = this.propertiesOf(index === 1 ? this.dev1 : this.dev2);
    return props.indexOf(index === 1 ? this.prop1 : this.prop2);
  }

  private save(): void {
    const name: string = this.ruleName.trim();
    if (name.length === 0) {
      this.errorText = '请填写规则名称';
      return;
    }
    const conditions: Condition[] = [this.buildCondition(this.metric1, this.op1, this.num1, this.flag1)];
    if (this.useCond2) {
      conditions.push(this.buildCondition(this.metric2, this.op2, this.num2, this.flag2));
    }
    const actions: Action[] = [this.buildAction(this.dev1, this.prop1, this.actNum1, this.actFlag1)];
    if (this.useAct2) {
      actions.push(this.buildAction(this.dev2, this.prop2, this.actNum2, this.actFlag2));
    }

    const rule: Rule = {
      id: this.editingId.length > 0 ? this.editingId : newRuleId(),
      name: name,
      enabled: this.ruleEnabled,
      priority: this.priority,
      logic: this.logic,
      conditions: conditions,
      actions: actions,
      createdAt: this.createdAt > 0 ? this.createdAt : Date.now()
    };

    const errors: string[] = validateRule(rule);
    const invalid: Condition[] = conditions.filter((c: Condition) => !isValidCondition(c));
    if (errors.length > 0 || invalid.length > 0) {
      this.errorText = errors.length > 0 ? errors[0] : '条件不合法';
      return;
    }

    this.errorText = '';
    DormStore.get().upsertRule(rule);
    router.back();
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#8A8F9C')
      .width('100%')
      .margin({ top: 6, bottom: 8 })
  }

  @Builder
  conditionBlock(index: number) {
    Column() {
      Row() {
        Text(index === 1 ? '条件一' : '条件二')
          .fontSize(12)
          .fontColor('#5B6070')
        Blank()
        if (index === 2) {
          Text('移除')
            .fontSize(12)
            .fontColor('#E5484D')
            .onClick(() => {
              this.useCond2 = false;
            })
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row({ space: 8 }) {
        Select(this.metricOptions())
          .selected(this.metricIndex(index))
          .value(metricLabel(index === 1 ? this.metric1 : this.metric2))
          .layoutWeight(1)
          .onSelect((i: number, value: string) => {
            const metrics: MetricKey[] = ['temperature', 'illuminance', 'humidity', 'presence'];
            const picked: MetricKey = metrics[i];
            if (index === 1) {
              this.metric1 = picked;
              this.op1 = picked === 'presence' ? '==' : '>';
            } else {
              this.metric2 = picked;
              this.op2 = picked === 'presence' ? '==' : '>';
            }
          })

        Select(this.opOptions())
          .selected(this.opIndex(index))
          .value(index === 1 ? this.op1 : this.op2)
          .width(88)
          .onSelect((i: number, value: string) => {
            const ops: Operator[] = ['>', '>=', '<', '<=', '==', '!='];
            if (index === 1) {
              this.op1 = ops[i];
            } else {
              this.op2 = ops[i];
            }
          })
      }
      .width('100%')

      if ((index === 1 ? this.metric1 : this.metric2) === 'presence') {
        Row() {
          Text('要求：')
            .fontSize(12)
            .fontColor('#5B6070')
          Toggle({ type: ToggleType.Switch, isOn: index === 1 ? this.flag1 : this.flag2 })
            .onChange((isOn: boolean) => {
              if (index === 1) {
                this.flag1 = isOn;
              } else {
                this.flag2 = isOn;
              }
            })
          Text(index === 1 ? (this.flag1 ? '有人' : '无人') : (this.flag2 ? '有人' : '无人'))
            .fontSize(12)
            .fontColor('#1A1D29')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 10 })
      } else {
        Text(`${(index === 1 ? this.num1 : this.num2).toString()}${metricUnit(index === 1 ? this.metric1 : this.metric2)}`)
          .fontSize(13)
          .fontColor('#2F6BFF')
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 8 })

        Slider({
          value: index === 1 ? this.num1 : this.num2,
          min: this.metricRange(index === 1 ? this.metric1 : this.metric2)[0],
          max: this.metricRange(index === 1 ? this.metric1 : this.metric2)[1],
          step: this.metricRange(index === 1 ? this.metric1 : this.metric2)[2],
          style: SliderStyle.OutSet
        })
          .selectedColor('#2F6BFF')
          .trackColor('#E6E9F2')
          .onChange((value: number) => {
            if (index === 1) {
              this.num1 = value;
            } else {
              this.num2 = value;
            }
          })
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor('#F7F8FB')
    .margin({ bottom: 10 })
  }

  @Builder
  actionBlock(index: number) {
    Column() {
      Row() {
        Text(index === 1 ? '动作一' : '动作二')
          .fontSize(12)
          .fontColor('#5B6070')
        Blank()
        if (index === 2) {
          Text('移除')
            .fontSize(12)
            .fontColor('#E5484D')
            .onClick(() => {
              this.useAct2 = false;
            })
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row({ space: 8 }) {
        Select(this.deviceOptions())
          .selected(this.deviceIndex(index))
          .value(this.deviceName(index === 1 ? this.dev1 : this.dev2))
          .layoutWeight(1)
          .onSelect((i: number, value: string) => {
            const picked: string = this.deviceList[i].id;
            if (index === 1) {
              this.dev1 = picked;
              this.prop1 = this.propertiesOf(picked)[0];
            } else {
              this.dev2 = picked;
              this.prop2 = this.propertiesOf(picked)[0];
            }
          })

        Select(this.propOptions(index === 1 ? this.dev1 : this.dev2))
          .selected(this.propIndex(index))
          .value(this.propLabel(index === 1 ? this.prop1 : this.prop2))
          .width(110)
          .onSelect((i: number, value: string) => {
            const props: DeviceProperty[] = this.propertiesOf(index === 1 ? this.dev1 : this.dev2);
            if (index === 1) {
              this.prop1 = props[i];
            } else {
              this.prop2 = props[i];
            }
          })
      }
      .width('100%')

      if ((index === 1 ? this.prop1 : this.prop2) === 'power') {
        Row() {
          Text('执行：')
            .fontSize(12)
            .fontColor('#5B6070')
          Toggle({ type: ToggleType.Switch, isOn: index === 1 ? this.actFlag1 : this.actFlag2 })
            .onChange((isOn: boolean) => {
              if (index === 1) {
                this.actFlag1 = isOn;
              } else {
                this.actFlag2 = isOn;
              }
            })
          Text(index === 1 ? (this.actFlag1 ? '打开' : '关闭') : (this.actFlag2 ? '打开' : '关闭'))
            .fontSize(12)
            .fontColor('#1A1D29')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 10 })
      } else {
        Text(`目标值：${(index === 1 ? this.actNum1 : this.actNum2).toString()}${this.actionUnit(index === 1 ? this.prop1 : this.prop2)}`)
          .fontSize(13)
          .fontColor('#22B07D')
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 10 })

        Slider({
          value: index === 1 ? this.actNum1 : this.actNum2,
          min: this.actionRange(index === 1 ? this.prop1 : this.prop2)[0],
          max: this.actionRange(index === 1 ? this.prop1 : this.prop2)[1],
          step: this.actionRange(index === 1 ? this.prop1 : this.prop2)[2],
          style: SliderStyle.OutSet
        })
          .selectedColor('#22B07D')
          .trackColor('#E6E9F2')
          .onChange((value: number) => {
            if (index === 1) {
              this.actNum1 = value;
            } else {
              this.actNum2 = value;
            }
          })
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor('#F7F8FB')
    .margin({ bottom: 10 })
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(26)
          .fontColor('#1A1D29')
          .width(36)
          .onClick(() => router.back())
        Text(this.editingId.length > 0 ? '编辑规则' : '新建规则')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1D29')
        Blank()
        Button('保存')
          .fontSize(13)
          .height(34)
          .backgroundColor('#2F6BFF')
          .onClick(() => this.save())
      }
      .width('100%')
      .padding({ left: 10, right: 14, top: 12, bottom: 10 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          this.sectionTitle('基本信息')
          Column() {
            TextInput({ text: this.ruleName, placeholder: '给规则起个名字，例如「高温开空调」' })
              .height(44)
              .borderRadius(10)
              .backgroundColor('#F7F8FB')
              .onChange((value: string) => {
                this.ruleName = value;
              })

            Row() {
              Text('组合逻辑')
                .fontSize(13)
                .fontColor('#5B6070')
              Blank()
              Text('同时满足(AND)')
                .fontSize(12)
                .fontColor(this.logic === 'AND' ? '#2F6BFF' : '#8A8F9C')
                .backgroundColor(this.logic === 'AND' ? '#EEF2FF' : '#F2F3F7')
                .borderRadius(8)
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .onClick(() => {
                  this.logic = 'AND';
                })
              Text('满足任一(OR)')
                .fontSize(12)
                .fontColor(this.logic === 'OR' ? '#2F6BFF' : '#8A8F9C')
                .backgroundColor(this.logic === 'OR' ? '#EEF2FF' : '#F2F3F7')
                .borderRadius(8)
                .margin({ left: 8 })
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .onClick(() => {
                  this.logic = 'OR';
                })
            }
            .width('100%')
            .margin({ top: 14 })

            Row() {
              Text(`优先级 P${this.priority}`)
                .fontSize(13)
                .fontColor('#5B6070')
              Blank()
              Text('数值越大越优先')
                .fontSize(11)
                .fontColor('#8A8F9C')
            }
            .width('100%')
            .margin({ top: 14 })

            Slider({ value: this.priority, min: 1, max: 10, step: 1, style: SliderStyle.OutSet })
              .selectedColor('#2F6BFF')
              .trackColor('#E6E9F2')
              .onChange((value: number) => {
                this.priority = Math.round(value);
              })
          }
          .width('100%')
          .padding(14)
          .borderRadius(14)
          .backgroundColor(Color.White)

          this.sectionTitle('触发条件')
          this.conditionBlock(1)
          if (this.useCond2) {
            this.conditionBlock(2)
          } else {
            Text('+ 添加第二个条件（双条件规则）')
              .fontSize(12)
              .fontColor('#2F6BFF')
              .width('100%')
              .padding({ top: 6, bottom: 12 })
              .onClick(() => {
                this.useCond2 = true;
              })
          }

          this.sectionTitle('执行动作')
          this.actionBlock(1)
          if (this.useAct2) {
            this.actionBlock(2)
          } else {
            Text('+ 添加第二个动作')
              .fontSize(12)
              .fontColor('#2F6BFF')
              .width('100%')
              .padding({ top: 6, bottom: 12 })
              .onClick(() => {
                this.useAct2 = true;
              })
          }

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor('#E5484D')
              .width('100%')
              .margin({ top: 4, bottom: 8 })
          }

          Button(this.editingId.length > 0 ? '保存修改' : '创建规则')
            .width('100%')
            .height(46)
            .backgroundColor('#2F6BFF')
            .margin({ top: 8, bottom: 30 })
            .onClick(() => this.save())
        }
        .padding({ left: 14, right: 14, top: 4 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F7')
  }
}
