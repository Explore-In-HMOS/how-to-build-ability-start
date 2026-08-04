import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0021;
const TAG = 'MockMessagingAbility';

/**
 * Lightweight mock target for the Message Notification route. On user
 * action it calls terminateSelfWithResult() so the router's
 * startAbilityForResult() call resolves with an AbilityResult (FR-07).
 * There is no real Messaging app integration (see Out of Scope).
 */
export default class MockMessagingAbility extends UIAbility {
  /** Hands want.parameters to MockMessagingPage without a router navigation. */
  private storage: LocalStorage = new LocalStorage();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const conversationId = (want.parameters?.conversationId as string) ?? 'unknown';
    const sender = (want.parameters?.sender as string) ?? 'unknown';
    this.storage.setOrCreate('conversationId', conversationId);
    this.storage.setOrCreate('sender', sender);
    hilog.info(DOMAIN, TAG, 'onCreate conversationId=%{public}s sender=%{public}s', conversationId, sender);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/MockMessagingPage', this.storage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
      }
    });
  }
}
