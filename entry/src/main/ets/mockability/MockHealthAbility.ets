import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0020;
const TAG = 'MockHealthAbility';

/**
 * Lightweight mock target for the Health Notification route. It only reads
 * the "page"/"source" the router put in want.parameters and displays them -
 * there is no real Health Kit integration (see Out of Scope).
 */
export default class MockHealthAbility extends UIAbility {
  /** Hands want.parameters to MockHealthPage without a router navigation. */
  private storage: LocalStorage = new LocalStorage();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const page = (want.parameters?.page as string) ?? 'unknown';
    const source = (want.parameters?.source as string) ?? 'unknown';
    this.storage.setOrCreate('page', page);
    this.storage.setOrCreate('source', source);
    hilog.info(DOMAIN, TAG, 'onCreate page=%{public}s source=%{public}s', page, source);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/MockHealthPage', this.storage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
      }
    });
  }
}
