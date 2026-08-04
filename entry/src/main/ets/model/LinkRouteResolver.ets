import { Want, Permissions } from '@kit.AbilityKit';
import { HEALTH_ROUTE_PERMISSION, RouteTriggerType } from './RouteModels';

/** Bundle every mock target ability lives in (see AppScope/app.json5). */
const BUNDLE_NAME = 'com.hmosdemos.wearable.how_to_build_ability_start';

/** A trigger resolves to a Want, launched via startAbility()/startAbilityForResult(). */
export interface WantRouteTarget {
  kind: 'want';
  want: Want;
  /** Set only for routes that must be permission-checked before launch (FR-08). */
  requiredPermission?: Permissions;
  /** Whether the caller should wait for the target's AbilityResult (FR-07). */
  expectsResult: boolean;
}

/** A trigger resolves to a URL, opened via openLink() (FR-04). */
export interface UrlRouteTarget {
  kind: 'url';
  url: string;
}

export type RouteTarget = WantRouteTarget | UrlRouteTarget;

/**
 * Maps a mock trigger to either a Want (for startAbility family calls) or a
 * URL (for openLink), per the Architecture Overview's LinkRouteResolver
 * responsibility (FR-02).
 */
export class LinkRouteResolver {
  static resolve(trigger: RouteTriggerType): RouteTarget {
    if (trigger === RouteTriggerType.HEALTH_NOTIFICATION) {
      const want: Want = {
        bundleName: BUNDLE_NAME,
        abilityName: 'MockHealthAbility',
        parameters: {
          page: 'todaySummary',
          source: 'notification'
        }
      };
      return { kind: 'want', want, requiredPermission: HEALTH_ROUTE_PERMISSION, expectsResult: false };
    }

    if (trigger === RouteTriggerType.MESSAGE_NOTIFICATION) {
      const want: Want = {
        bundleName: BUNDLE_NAME,
        abilityName: 'MockMessagingAbility',
        parameters: {
          conversationId: 'demo-conversation-1',
          sender: 'Alex'
        }
      };
      return { kind: 'want', want, expectsResult: true };
    }

    // RouteTriggerType.CUSTOM_LINK: no real App Linking domain is verified for
    // this sample, so openLink() will always fall through past App Linking /
    // Deep Linking to the system browser (see Out of Scope).
    return { kind: 'url', url: 'test' };
  }
}
