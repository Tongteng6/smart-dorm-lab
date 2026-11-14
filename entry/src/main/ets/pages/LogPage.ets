import { router } from '@kit.ArkUI';
import { deviceIcon } from '../common/Formatters';
import { LogEntry, LogReject, LogStep, formatTime, logSummary } from '../model/LogEntry';
import { DormStore } from '../viewmodel/DormStore';

@Entry
@Component
struct LogPage {
  @State logs: LogEntry[] = [];

  aboutToAppear(): void {
    this.logs = DormStore.get().logs.slice();
  }

  private stepText(step: LogStep): string {
    const from: string = `${step.fromValue}`;
    const to: string = `${step.toValue}`;
    const status: string = step.status === 'applied' ? '执行' : '无变化';
    return `#${step.order} ${step.ruleName} → ${step.deviceName}.${step.property}：${from} → ${to}（${status}）`;
  }

  private rejectText(r: LogReject): string {
    return `${r.ruleName} → ${r.deviceId}.${r.property} = ${r.wanted}，被「${r.keptByRuleName}」覆盖：${r.reason}`;
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(26)
          .fontColor('#1A1D29')
          .width(36)
          .onClick(() => router.back())
        Text('执行日志')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1D29')
        Blank()
        Text('清空')
          .fontSize(13)
          .fontColor('#E5484D')
          .onClick(() => {
            AlertDialog.show({
              title: '清空日志',
              message: '执行记录将全部删除，确定继续？',
              primaryButton: { value: '取消', action: () => { } },
              secondaryButton: {
                value: '清空',
                fontColor: '#E5484D',
                action: () => {
                  DormStore.get().clearLogs();
                  this.logs = [];
                }
              }
            });
          })
      }
      .width('100%')
      .padding({ left: 10, right: 16, top: 12, bottom: 10 })
      .backgroundColor(Color.White)

      if (this.logs.length === 0) {
        Column() {
          Text('暂无执行记录')
            .fontSize(15)
            .fontColor('#1A1D29')
          Text('回到首页调整环境，规则命中后会在这里留痕')
            .fontSize(12)
            .fontColor('#8A8F9C')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.logs, (log: LogEntry) => {
            ListItem() {
              Column() {
                Row() {
                  Text(formatTime(log.ts))
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A1D29')
                  Text(`命中 ${log.matchedRuleIds.length} 条`)
                    .fontSize(10)
                    .fontColor('#2F6BFF')
                    .backgroundColor('#EEF2FF')
                    .borderRadius(6)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .margin({ left: 8 })
                  Blank()
                  Text(`${log.steps.length} 个动作`)
                    .fontSize(11)
                    .fontColor('#8A8F9C')
                }
                .width('100%')

                Text(logSummary(log))
                  .fontSize(11)
                  .fontColor('#8A8F9C')
                  .margin({ top: 4 })
                  .width('100%')

                ForEach(log.steps, (step: LogStep) => {
                  Text(this.stepText(step))
                    .fontSize(11)
                    .fontColor('#22B07D')
                    .margin({ top: 6 })
                    .width('100%')
                }, (step: LogStep) => `${log.id}-${step.order}`)

                ForEach(log.rejected, (r: LogReject) => {
                  Text(this.rejectText(r))
                    .fontSize(11)
                    .fontColor('#E5484D')
                    .margin({ top: 6 })
                    .width('100%')
                }, (r: LogReject) => `${log.id}-${r.ruleId}-${r.property}`)
              }
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor(Color.White)
            }
          }, (log: LogEntry) => log.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F7')
  }
}
