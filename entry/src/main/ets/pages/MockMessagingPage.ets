import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0022;
const TAG = 'MockMessagingPage';

/**
 * UI for MockMessagingAbility. Tapping "Reply" or "Ignore" calls
 * terminateSelfWithResult() so the AbilityResult flows back to
 * RouteResultPage via AbilityLaunchService's startAbilityForResult() call
 * (FR-07).
 *
 * Round-watch layout: content is centered in the vertical middle of the
 * circle and both actions use capsule buttons full-width within the safe
 * zone, matching watch button conventions.
 */
@Entry({ useSharedStorage: true })
@Component
struct MockMessagingPage {
  @LocalStorageProp('conversationId') conversationId: string = '';
  @LocalStorageProp('sender') sender: string = '';

  /** resultCode 1 = replied, 0 = ignored - read back as AbilityResult.resultCode. */
  private finish(resultCode: number, replyText: string): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    context.terminateSelfWithResult({
      resultCode,
      want: {
        parameters: {
          conversationId: this.conversationId,
          replyText,
          repliedAt: Date.now()
        }
      }
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'terminateSelfWithResult failed %{public}d %{public}s', err.code, err.message);
    });
  }

  build() {
    Column({ space: 12 }) {
      Text($r('app.string.mock_messaging_title'))
        .fontSize($r('app.float.page_title_font_size'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text($r('app.string.mock_messaging_sender_label', this.sender))
        .fontSize($r('app.float.detail_value_font_size'))
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Button($r('app.string.mock_messaging_reply_button'), { type: ButtonType.Capsule })
        .fontSize($r('app.float.setting_label_font_size'))
        .width('100%')
        .backgroundColor($r('app.color.primary_button_background'))
        .fontColor($r('app.color.primary_button_text'))
        .onClick(() => this.finish(1, 'On my way!'))

      Button($r('app.string.mock_messaging_ignore_button'), { type: ButtonType.Capsule })
        .fontSize($r('app.float.setting_label_font_size'))
        .width('100%')
        .backgroundColor($r('app.color.secondary_button_background'))
        .fontColor($r('app.color.secondary_button_text'))
        .onClick(() => this.finish(0, ''))
    }
    .width('100%')
    .height('100%')
    .padding($r('app.float.page_padding'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
