import { AbilityConstant, CompletionHandler, StartOptions } from '@kit.AbilityKit';
import { display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RouteSettings } from './RouteModels';

const DOMAIN = 0x0010;
const TAG = 'StartOptionsBuilder';

/**
 * Builds the StartOptions used by every Want-based route from the router's
 * current in-app settings (displayId / windowMode / withAnimation), per the
 * StartOptionsBuilder responsibility in the Architecture Overview (FR-03).
 * https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-app-ability-startoptions
 */
export class StartOptionsBuilder {
  static build(settings: RouteSettings, completionHandler: CompletionHandler): StartOptions {
    let displayId = 0;
    try {
      // Watches typically expose only one display, but this still wires
      // StartOptions.displayId to a real platform-reported value (FR-03).
      displayId = display.getDefaultDisplaySync().id;
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'getDefaultDisplaySync failed, defaulting to displayId 0: %{public}s',
        JSON.stringify(error));
    }

    return {
      displayId,
      // This SDK's AbilityConstant.WindowMode only defines
      // WINDOW_MODE_FULLSCREEN, WINDOW_MODE_SPLIT_PRIMARY and
      // WINDOW_MODE_SPLIT_SECONDARY - there is no floating or "system
      // default" member, and split-screen only applies to tablets/2-in-1
      // devices. The toggle still exercises the real field end-to-end even
      // though a watch only ever renders fullscreen.
      windowMode: settings.useFullscreenWindowMode
        ? AbilityConstant.WindowMode.WINDOW_MODE_FULLSCREEN
        : AbilityConstant.WindowMode.WINDOW_MODE_SPLIT_PRIMARY,
      withAnimation: settings.withAnimation,
      completionHandler
    };
  }
}
