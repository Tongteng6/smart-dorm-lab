import { router } from '@kit.ArkUI';
import { Device } from '../model/Device';
import { Rule, actionText, conditionText, ruleSummary } from '../model/Rule';
import { DormStore } from '../viewmodel/DormStore';

@Entry
@Component
struct RuleListPage {
  @State rules: Rule[] = [];
  @State deviceNames: Map<string, string> = new Map<string, string>();

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    const store: DormStore = DormStore.get();
    this.rules = store.rules.slice();
    const map: Map<string, string> = new Map<string, string>();
    store.devices.forEach((d: Device) => map.set(d.id, d.name));
    this.deviceNames = map;
  }

  private actionSummary(rule: Rule): string {
    return rule.actions
      .map((a) => actionText(a, this.deviceNames.get(a.deviceId) ?? a.deviceId))
      .join('；');
  }

  private confirmDelete(rule: Rule): void {
    AlertDialog.show({
      title: '删除规则',
      message: `确定删除「${rule.name}」吗？该操作不可撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#E5484D',
        action: () => {
          DormStore.get().deleteRule(rule.id);
          this.reload();
        }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(26)
          .fontColor('#1A1D29')
          .width(36)
          .onClick(() => router.back())
        Text('规则列表')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1D29')
        Blank()
        Button('+ 新建')
          .fontSize(13)
          .height(34)
          .backgroundColor('#2F6BFF')
          .onClick(() => router.pushUrl({ url: 'pages/RuleEditPage' }))
      }
      .width('100%')
      .padding({ left: 10, right: 14, top: 12, bottom: 10 })
      .backgroundColor(Color.White)

      if (this.rules.length === 0) {
        Column() {
          Text('还没有规则')
            .fontSize(15)
            .fontColor('#1A1D29')
          Text('点击右上角「新建」，让设备自己动起来')
            .fontSize(12)
            .fontColor('#8A8F9C')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.rules, (rule: Rule) => {
            ListItem() {
              Column() {
                Row() {
                  Text(rule.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(rule.enabled ? '#1A1D29' : '#A9AEBA')
                  Text(`P${rule.priority}`)
                    .fontSize(10)
                    .fontColor('#2F6BFF')
                    .backgroundColor('#EEF2FF')
                    .borderRadius(6)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .margin({ left: 8 })
                  Blank()
                  Toggle({ type: ToggleType.Switch, isOn: rule.enabled })
                    .onChange(() => {
                      DormStore.get().toggleRule(rule.id);
                      this.reload();
                    })
                }
                .width('100%')

                Text(ruleSummary(rule))
                  .fontSize(12)
                  .fontColor('#5B6070')
                  .margin({ top: 8 })
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(`→ ${this.actionSummary(rule)}`)
                  .fontSize(12)
                  .fontColor('#22B07D')
                  .margin({ top: 4 })
                  .width('100%')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor(Color.White)
              .onClick(() => {
                router.pushUrl({ url: 'pages/RuleEditPage', params: { ruleId: rule.id } });
              })
              .gesture(
                LongPressGesture().onAction(() => this.confirmDelete(rule))
              )
            }
          }, (rule: Rule) => rule.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 14, right: 14, top: 12 })
        .scrollBar(BarState.Off)
      }

      Text('长按规则可删除')
        .fontSize(11)
        .fontColor('#A9AEBA')
        .margin({ top: 8, bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F7')
  }
}
