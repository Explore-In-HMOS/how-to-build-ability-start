import { Permissions } from '@kit.AbilityKit';

/**
 * The three mock triggers the Route Trigger screen can simulate (FR-01).
 */
export enum RouteTriggerType {
  HEALTH_NOTIFICATION = 'HEALTH_NOTIFICATION',
  MESSAGE_NOTIFICATION = 'MESSAGE_NOTIFICATION',
  CUSTOM_LINK = 'CUSTOM_LINK'
}

/**
 * The route outcome shown on the Route Result screen (FR-09).
 */
export enum RouteStatus {
  SUCCESS = 'SUCCESS',
  FALLBACK_BROWSER = 'FALLBACK_BROWSER',
  FAILED = 'FAILED',
  PERMISSION_DENIED = 'PERMISSION_DENIED'
}

/**
 * In-app settings feeding StartOptionsBuilder and the OpenLinkOptions used for
 * the Custom Universal Link route. Bound directly to the toggles on
 * RouteTriggerPage. @Observed so mutating a single field (e.g. `settings.
 * withAnimation = value`) re-renders the owning @State holder - a plain class
 * would only be observed on full reference reassignment.
 */
@Observed
export class RouteSettings {
  /** StartOptions.withAnimation (11+). */
  withAnimation: boolean = true;
  /**
   * StartOptions.windowMode (12+): true requests WINDOW_MODE_FULLSCREEN,
   * false requests WINDOW_MODE_SPLIT_PRIMARY (the only other mode this SDK
   * exposes; split-screen only actually applies on tablets/2-in-1 devices).
   */
  useFullscreenWindowMode: boolean = true;
  /** OpenLinkOptions.appLinkingOnly (12+). */
  appLinkingOnly: boolean = false;
  /** OpenLinkOptions.hideFailureTipDialog (21+). */
  hideFailureTipDialog: boolean = false;
}

/**
 * Snapshot of one completed (or failed) route attempt. Passed as the
 * NavDestination param from RouteTriggerPage to RouteResultPage.
 */
export interface RouteResultData {
  trigger: RouteTriggerType;
  status: RouteStatus;
  startOptionsSummary: string;
  completionOutcome: string;
  abilityResultSummary: string;
  message: string;
}

/** Permission requested before the Health Notification route launches (FR-08). */
export const HEALTH_ROUTE_PERMISSION: Permissions = 'ohos.permission.ACTIVITY_MOTION';
