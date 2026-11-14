import { router } from '@kit.ArkUI';
import { EnvState } from '../model/EnvState';
import { Scenario } from '../model/Scenario';
import { DormStore } from '../viewmodel/DormStore';

@Entry
@Component
struct ScenarioPage {
  @State scenarios: Scenario[] = [];
  @State newName: string = '';
  @State tip: string = '';

  aboutToAppear(): void {
    this.scenarios = DormStore.get().scenarios.slice();
  }

  private envText(env: EnvState): string {
    const who: string = env.presence ? '有人' : '无人';
    return `${env.temperature}°C · ${env.illuminance}lux · ${env.humidity}% · ${who}`;
  }

  private apply(s: Scenario): void {
    DormStore.get().applyScenario(s.id);
    this.tip = `已应用「${s.name}」`;
  }

  private addCurrent(): void {
    const name: string = this.newName.trim();
    if (name.length === 0) {
      this.tip = '请先填写场景名称';
      return;
    }
    DormStore.get().saveScenario(name);
    this.scenarios = DormStore.get().scenarios.slice();
    this.newName = '';
    this.tip = `已保存「${name}」`;
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(26)
          .fontColor('#1A1D29')
          .width(36)
          .onClick(() => router.back())
        Text('场景演练')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1D29')
      }
      .width('100%')
      .padding({ left: 10, right: 16, top: 12, bottom: 10 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Text('一键切换环境，观察规则联动与冲突仲裁结果。')
            .fontSize(12)
            .fontColor('#8A8F9C')
            .width('100%')
            .margin({ top: 12, bottom: 10 })

          ForEach(this.scenarios, (s: Scenario) => {
            Row() {
              Text(s.icon)
                .fontSize(22)
              Column() {
                Text(s.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1D29')
                Text(this.envText(s.env))
                  .fontSize(11)
                  .fontColor('#8A8F9C')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 10 })

              Button('应用')
                .fontSize(12)
                .height(32)
                .backgroundColor('#EEF2FF')
                .fontColor('#2F6BFF')
                .onClick(() => this.apply(s))

              Text('✕')
                .fontSize(14)
                .fontColor('#C3C7D1')
                .margin({ left: 10 })
                .onClick(() => {
                  DormStore.get().deleteScenario(s.id);
                  this.scenarios = DormStore.get().scenarios.slice();
                })
            }
            .width('100%')
            .padding(14)
            .borderRadius(14)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })
          }, (s: Scenario) => s.id)

          Column() {
            Text('把当前环境存成新场景')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1D29')
              .width('100%')
            TextInput({ text: this.newName, placeholder: '场景名称，例如「午休」' })
              .height(42)
              .borderRadius(10)
              .backgroundColor('#F7F8FB')
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.newName = value;
              })
            Button('保存当前环境')
              .width('100%')
              .height(42)
              .fontSize(13)
              .backgroundColor('#2F6BFF')
              .margin({ top: 10 })
              .onClick(() => this.addCurrent())
            if (this.tip.length > 0) {
              Text(this.tip)
                .fontSize(12)
                .fontColor('#22B07D')
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(14)
          .borderRadius(14)
          .backgroundColor(Color.White)
          .margin({ top: 4, bottom: 24 })
        }
        .padding({ left: 14, right: 14 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F7')
  }
}
