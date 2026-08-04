import { abilityAccessCtrl, bundleManager, common, CompletionHandler, OpenLinkOptions, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LinkRouteResolver, RouteTarget, UrlRouteTarget, WantRouteTarget } from '../model/LinkRouteResolver';
import { RouteResultData, RouteSettings, RouteStatus, RouteTriggerType } from '../model/RouteModels';
import { StartOptionsBuilder } from '../model/StartOptionsBuilder';

const DOMAIN = 0x0011;
const TAG = 'AbilityLaunchService';

/**
 * Wraps every UIAbilityContext call the router needs (FR-03 to FR-08):
 * requestPermissionsFromUser(), startAbility()/startAbilityForResult(), and
 * openLink(). This is the single place that turns a raw API outcome into the
 * RouteResultData shown on RouteResultPage.
 * https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-app-ability-common#uiabilitycontext
 */
export class AbilityLaunchService {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /** Resolves the trigger and drives it through the right launch path. */
  async launch(trigger: RouteTriggerType, settings: RouteSettings): Promise<RouteResultData> {
    const target: RouteTarget = LinkRouteResolver.resolve(trigger);
    if (target.kind === 'want') {
      return this.launchWant(trigger, target, settings);
    }
    return this.launchUrl(trigger, target, settings);
  }

  private async launchWant(
    trigger: RouteTriggerType,
    target: WantRouteTarget,
    settings: RouteSettings
  ): Promise<RouteResultData> {
    if (target.requiredPermission) {
      const granted = await this.ensurePermission(target.requiredPermission);
      if (!granted) {
        return {
          trigger,
          status: RouteStatus.PERMISSION_DENIED,
          startOptionsSummary: 'n/a - launch skipped',
          completionOutcome: 'n/a - launch skipped',
          abilityResultSummary: 'n/a',
          message: `User denied required permission: ${target.requiredPermission}`
        };
      }
    }

    // CompletionHandler reports whether the launch REQUEST was accepted, which
    // is independent of when/how the target ability later terminates (FR-05).
    let completionOutcome = 'Pending';
    const completionHandler: CompletionHandler = {
      onRequestSuccess: (elementName: bundleManager.ElementName, message: string): void => {
        completionOutcome = `onRequestSuccess: ${elementName.bundleName}/${elementName.abilityName}`;
        hilog.info(DOMAIN, TAG, 'CompletionHandler.onRequestSuccess %{public}s', message);
      },
      onRequestFailure: (_elementName: bundleManager.ElementName, message: string): void => {
        completionOutcome = `onRequestFailure: ${this.extractErrMsg(message)}`;
        hilog.error(DOMAIN, TAG, 'CompletionHandler.onRequestFailure %{public}s', message);
      }
    };

    const options = StartOptionsBuilder.build(settings, completionHandler);
    const startOptionsSummary =
      `windowMode=${options.windowMode}, displayId=${options.displayId}, withAnimation=${options.withAnimation}`;

    if (!target.expectsResult) {
      // Health route: fire-and-forget startAbility(), Promise<void> resolves
      // once the launch request is handed off (FR-03).
      try {
        await this.context.startAbility(target.want, options);
        return {
          trigger,
          status: RouteStatus.SUCCESS,
          startOptionsSummary,
          completionOutcome,
          abilityResultSummary: 'n/a (fire-and-forget route, no AbilityResult expected)',
          message: 'startAbility() resolved - target ability launched.'
        };
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, 'startAbility failed %{public}d %{public}s', error.code, error.message);
        return {
          trigger,
          status: RouteStatus.FAILED,
          startOptionsSummary,
          completionOutcome,
          abilityResultSummary: 'n/a',
          message: `startAbility failed: [${error.code}] ${error.message}`
        };
      }
    }

    // Message route: startAbilityForResult() so terminateSelfWithResult() on
    // MockMessagingAbility can hand an AbilityResult back (FR-07). The result
    // is funnelled through an AbilityStartCallback-shaped handler (the same
    // onError/onResult contract UIAbilityContext.startAbilityByType() takes a
    // callback object instead of a promise for) so every launch style in this
    // router reports through one consistent callback contract (FR-06).
    const abilityStartCallback: common.AbilityStartCallback = {
      onError: (code: number, name: string, message: string): void => {
        hilog.error(DOMAIN, TAG, 'AbilityStartCallback.onError %{public}d %{public}s %{public}s', code, name, message);
      },
      onResult: (result: common.AbilityResult): void => {
        hilog.info(DOMAIN, TAG, 'AbilityStartCallback.onResult resultCode=%{public}d', result.resultCode);
      }
    };

    try {
      const result = await this.context.startAbilityForResult(target.want, options);
      abilityStartCallback.onResult?.(result);
      const abilityResultSummary = `resultCode=${result.resultCode}, want.parameters=${JSON.stringify(result.want?.parameters ?? {})}`;

      if (result.resultCode === -1) {
        // Abnormal termination of the target ability (e.g. it was killed).
        return {
          trigger,
          status: RouteStatus.FAILED,
          startOptionsSummary,
          completionOutcome,
          abilityResultSummary,
          message: 'Target ability terminated abnormally (resultCode=-1).'
        };
      }

      return {
        trigger,
        status: RouteStatus.SUCCESS,
        startOptionsSummary,
        completionOutcome,
        abilityResultSummary,
        message: 'Reply received from the mock Messaging ability.'
      };
    } catch (err) {
      const error = err as BusinessError;
      abilityStartCallback.onError(error.code, error.name, error.message);
      return {
        trigger,
        status: RouteStatus.FAILED,
        startOptionsSummary,
        completionOutcome,
        abilityResultSummary: 'n/a',
        message: `startAbilityForResult failed: [${error.code}] ${error.message}`
      };
    }
  }

  private async launchUrl(
    trigger: RouteTriggerType,
    target: UrlRouteTarget,
    settings: RouteSettings
  ): Promise<RouteResultData> {
    let completionOutcome = 'Pending';
    const completionHandler: CompletionHandler = {
      onRequestSuccess: (_elementName: bundleManager.ElementName, message: string): void => {
        completionOutcome = 'onRequestSuccess';
        hilog.info(DOMAIN, TAG, 'openLink CompletionHandler.onRequestSuccess %{public}s', message);
      },
      onRequestFailure: (_elementName: bundleManager.ElementName, message: string): void => {
        completionOutcome = `onRequestFailure: ${this.extractErrMsg(message)}`;
        hilog.error(DOMAIN, TAG, 'openLink CompletionHandler.onRequestFailure %{public}s', message);
      }
    };

    const openLinkOptions: OpenLinkOptions = {
      appLinkingOnly: settings.appLinkingOnly,
      parameters: { source: 'route-trigger-page' },
      hideFailureTipDialog: settings.hideFailureTipDialog,
      completionHandler
    };
    const startOptionsSummary =
      `appLinkingOnly=${settings.appLinkingOnly}, hideFailureTipDialog=${settings.hideFailureTipDialog}`;

    try {
      await this.context.openLink(target.url, openLinkOptions);
      // No App Linking domain is verified for this sample (see Out of Scope),
      // so a resolved openLink() call here always means the system fell back
      // to Deep Linking or the browser rather than a genuine App Link match.
      return {
        trigger,
        status: RouteStatus.FALLBACK_BROWSER,
        startOptionsSummary,
        completionOutcome,
        abilityResultSummary: 'n/a (URL route, no AbilityResult expected)',
        message: `Opened ${target.url} (no App Link match, fell back to browser).`
      };
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'openLink failed %{public}d %{public}s', error.code, error.message);
      return {
        trigger,
        status: RouteStatus.FAILED,
        startOptionsSummary,
        completionOutcome,
        abilityResultSummary: 'n/a',
        message: `openLink failed: [${error.code}] ${error.message}`
      };
    }
  }

  /** Requests the permission a route needs, returning whether it was granted (FR-08). */
  private async ensurePermission(permission: Permissions): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context, [permission]);
      const index = result.permissions.indexOf(permission);
      return index !== -1 && result.authResults[index] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'requestPermissionsFromUser failed %{public}d %{public}s', error.code, error.message);
      return false;
    }
  }

  /** CompletionHandler.onRequestFailure's message is a JSON string carrying an errMsg field. */
  private extractErrMsg(message: string): string {
    try {
      const parsed = JSON.parse(message) as Record<string, string>;
      return parsed.errMsg ?? message;
    } catch {
      return message;
    }
  }
}
