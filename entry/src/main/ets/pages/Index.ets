import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { deviceIcon, deviceIsActive, deviceStatusText } from '../common/Formatters';
import { Device } from '../model/Device';
import { EnvState } from '../model/EnvState';
import { LogEntry, formatTime, logSummary } from '../model/LogEntry';
import { Scenario } from '../model/Scenario';
import { DormStore } from '../viewmodel/DormStore';

@Entry
@Component
struct Index {
  // 用基本类型承载环境数据：@State 对基本类型的刷新最可靠
  @State temperature: number = 26;
  @State illuminance: number = 500;
  @State humidity: number = 55;
  @State presence: boolean = true;

  @State devices: Device[] = [];
  @State scenarios: Scenario[] = [];
  @State latestSummary: string = '暂无执行记录';
  @State latestTime: string = '';
  @State totalRules: number = 0;
  @State enabledRules: number = 0;

  aboutToAppear(): void {
    this.bootstrap();
  }

  onPageShow(): void {
    this.syncAll();
  }

  private async bootstrap(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    await DormStore.get().init(context);
    this.syncAll();
  }

  private syncAll(): void {
    const store: DormStore = DormStore.get();
    this.temperature = store.env.temperature;
    this.illuminance = store.env.illuminance;
    this.humidity = store.env.humidity;
    this.presence = store.env.presence;
    this.devices = store.devices.slice();
    this.scenarios = store.scenarios.slice();
    this.totalRules = store.rules.length;
    this.enabledRules = store.rules.filter((r) => r.enabled).length;
    const log: LogEntry | undefined = store.lastLog();
    if (log === undefined) {
      this.latestSummary = '暂无执行记录';
      this.latestTime = '';
    } else {
      this.latestSummary = logSummary(log);
      this.latestTime = formatTime(log.ts);
    }
  }

  private currentEnv(): EnvState {
    return {
      temperature: this.temperature,
      illuminance: this.illuminance,
      humidity: this.humidity,
      presence: this.presence
    };
  }

  private onTemp(value: number, mode: SliderChangeMode): void {
    this.temperature = value;
    DormStore.get().previewEnv(this.currentEnv());
    this.devices = DormStore.get().devices.slice();
    if (mode === SliderChangeMode.End) {
      DormStore.get().setEnv(this.currentEnv());
    }
  }

  private onLux(value: number, mode: SliderChangeMode): void {
    this.illuminance = value;
    DormStore.get().previewEnv(this.currentEnv());
    this.devices = DormStore.get().devices.slice();
    if (mode === SliderChangeMode.End) {
      DormStore.get().setEnv(this.currentEnv());
    }
  }

  private onHumidity(value: number, mode: SliderChangeMode): void {
    this.humidity = value;
    DormStore.get().previewEnv(this.currentEnv());
    this.devices = DormStore.get().devices.slice();
    if (mode === SliderChangeMode.End) {
      DormStore.get().setEnv(this.currentEnv());
    }
  }

  private onPresence(isOn: boolean): void {
    this.presence = isOn;
    const next: EnvState = this.currentEnv();
    DormStore.get().setEnv(next);
    this.syncAll();
  }

  private go(url: string): void {
    router.pushUrl({ url: url });
  }

  /** ForEach 的 key 必须包含可变状态，否则 ArkUI 会复用旧组件不重建 */
  private deviceKey(d: Device): string {
    return `${d.id}-${d.state.power}-${d.state.brightness}-${d.state.targetTemp}-${d.state.openness}-${d.state.speed}`;
  }

  private activeCount(): number {
    return this.devices.filter((d: Device) => deviceIsActive(d)).length;
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('联动实验室')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1D29')
          Text('智能宿舍自动化规则编排')
            .fontSize(12)
            .fontColor('#8A8F9C')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text(`${this.activeCount()} 台运行`)
            .fontSize(13)
            .fontColor('#2F6BFF')
            .fontWeight(FontWeight.Medium)
          Text(`${this.enabledRules}/${this.totalRules} 条规则启用`)
            .fontSize(11)
            .fontColor('#8A8F9C')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Column() {
          // ===== 模拟环境 =====
          Column() {
            Row() {
              Column() {
                Text('模拟环境')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1D29')
                Text('拖动即生效，松手后自动保存')
                  .fontSize(11)
                  .fontColor('#8A8F9C')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Row() {
                Text(this.presence ? '有人' : '无人')
                  .fontSize(13)
                  .fontColor(this.presence ? '#2F6BFF' : '#8A8F9C')
                Toggle({ type: ToggleType.Switch, isOn: this.presence })
                  .onChange((isOn: boolean) => this.onPresence(isOn))
                  .margin({ left: 6 })
              }
            }
            .width('100%')

            Row() {
              Text('温度').fontSize(13).fontColor('#5B6070')
              Blank()
              Text(`${this.temperature.toFixed(1)}°C`).fontSize(13).fontColor('#1A1D29').fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ top: 14, bottom: 2 })

            Slider({ value: this.temperature, min: 10, max: 40, step: 0.5, style: SliderStyle.OutSet })
              .selectedColor('#2F6BFF')
              .trackColor('#E6E9F2')
              .onChange((value: number, mode: SliderChangeMode) => this.onTemp(value, mode))

            Row() {
              Text('光照').fontSize(13).fontColor('#5B6070')
              Blank()
              Text(`${this.illuminance} lux`).fontSize(13).fontColor('#1A1D29').fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ top: 14, bottom: 2 })

            Slider({ value: this.illuminance, min: 0, max: 1000, step: 10, style: SliderStyle.OutSet })
              .selectedColor('#F5A524')
              .trackColor('#E6E9F2')
              .onChange((value: number, mode: SliderChangeMode) => this.onLux(value, mode))

            Row() {
              Text('湿度').fontSize(13).fontColor('#5B6070')
              Blank()
              Text(`${this.humidity}%`).fontSize(13).fontColor('#1A1D29').fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ top: 14, bottom: 2 })

            Slider({ value: this.humidity, min: 0, max: 100, step: 1, style: SliderStyle.OutSet })
              .selectedColor('#22B07D')
              .trackColor('#E6E9F2')
              .onChange((value: number, mode: SliderChangeMode) => this.onHumidity(value, mode))
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor(Color.White)

          Column().height(14)

          // ===== 场景 =====
          Column() {
            Row() {
              Text('场景演练')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1D29')
              Blank()
              Text('查看更多 ›')
                .fontSize(12)
                .fontColor('#2F6BFF')
                .onClick(() => this.go('pages/ScenarioPage'))
            }
            .width('100%')
            .margin({ bottom: 10 })

            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.scenarios, (s: Scenario) => {
                  Column() {
                    Text(s.icon).fontSize(18)
                    Text(s.name).fontSize(12).fontColor('#1A1D29').margin({ top: 4 })
                  }
                  .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                  .borderRadius(12)
                  .backgroundColor('#F4F6FF')
                  .onClick(() => {
                    DormStore.get().applyScenario(s.id);
                    this.syncAll();
                  })
                }, (s: Scenario) => `${s.id}-${s.name}`)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor(Color.White)

          // ===== 设备状态 =====
          Column() {
            Row() {
              Text('设备状态')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1D29')
              Blank()
              Text('自动联动中').fontSize(11).fontColor('#22B07D')
            }
            .width('100%')
            .margin({ bottom: 10 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(this.devices, (d: Device) => {
                Column() {
                  Row() {
                    Text(deviceIcon(d)).fontSize(20)
                    Blank()
                    Text(deviceIsActive(d) ? '开' : '关')
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor(deviceIsActive(d) ? '#22B07D' : '#C3C7D1')
                      .borderRadius(8)
                      .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                  }
                  .width('100%')

                  Text(d.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A1D29')
                    .margin({ top: 8 })
                    .width('100%')
                    .textAlign(TextAlign.Start)

                  Text(deviceStatusText(d))
                    .fontSize(11)
                    .fontColor('#8A8F9C')
                    .margin({ top: 3 })
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('48.5%')
                .padding(14)
                .borderRadius(14)
                .backgroundColor(deviceIsActive(d) ? '#F2F6FF' : Color.White)
                .border({ width: 1, color: deviceIsActive(d) ? '#D6E2FF' : '#EDEFF4' })
                .margin({ bottom: 10 })
              }, (d: Device) => this.deviceKey(d))
            }
            .width('100%')
          }
          .width('100%')
          .margin({ top: 14 })

          // ===== 最近执行 =====
          Column() {
            Row() {
              Text('最近执行')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1D29')
              Blank()
              Text(this.latestTime).fontSize(12).fontColor('#8A8F9C')
            }
            .width('100%')

            Text(this.latestSummary)
              .fontSize(12)
              .fontColor('#5B6070')
              .margin({ top: 8 })
              .width('100%')

            Row() {
              Button('立即执行一次')
                .fontSize(13)
                .height(36)
                .backgroundColor('#2F6BFF')
                .layoutWeight(1)
                .onClick(() => {
                  DormStore.get().runOnce();
                  this.syncAll();
                })
              Button('查看全部日志')
                .fontSize(13)
                .height(36)
                .backgroundColor('#EEF2FF')
                .fontColor('#2F6BFF')
                .layoutWeight(1)
                .margin({ left: 10 })
                .onClick(() => this.go('pages/LogPage'))
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor(Color.White)
          .margin({ top: 4 })
        }
        .padding({ left: 14, right: 14, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // ===== 底部导航 =====
      Row() {
        Column() {
          Text('📋').fontSize(18)
          Text('规则').fontSize(11).fontColor('#5B6070').margin({ top: 2 })
        }
        .layoutWeight(1)
        .onClick(() => this.go('pages/RuleListPage'))

        Column() {
          Text('🕘').fontSize(18)
          Text('日志').fontSize(11).fontColor('#5B6070').margin({ top: 2 })
        }
        .layoutWeight(1)
        .onClick(() => this.go('pages/LogPage'))

        Column() {
          Text('🎬').fontSize(18)
          Text('场景').fontSize(11).fontColor('#5B6070').margin({ top: 2 })
        }
        .layoutWeight(1)
        .onClick(() => this.go('pages/ScenarioPage'))
      }
      .width('100%')
      .padding({ top: 8, bottom: 12 })
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#EDEFF4' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F7')
  }
}
