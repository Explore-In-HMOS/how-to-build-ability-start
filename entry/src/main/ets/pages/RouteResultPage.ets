import { ArcList, ArcListAttribute, ArcListItem, ArcListItemAttribute, LengthMetrics } from '@kit.ArkUI';
import { RouteResultData, RouteStatus, RouteTriggerType } from '../model/RouteModels';

/**
 * Width every ArcListItem's content is rendered at, leaving a left/right
 * gutter so cards, text and buttons stay clear of ArcList's own curved
 * edge/scroll indicator instead of touching it.
 */
const ARC_ITEM_WIDTH = '82%';

/**
 * RouteResultPage: shows the resolved route, the StartOptions used, the
 * CompletionHandler/AbilityStartCallback outcome, and the AbilityResult (if
 * any) for the trigger that was just launched (FR-09).
 *
 * Round-watch layout: everything - the title, the status headline, the
 * detail rows and the back/retry actions - lives inside a single
 * full-screen ArcList so the crown can page through them without any row
 * clipping against the curved bezel; giving ArcList less than the full
 * screen (e.g. a fixed header above it) throws off its arc curvature math.
 */
@Component
export struct RouteResultPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Prop result: RouteResultData;

  private statusLabel(): ResourceStr {
    if (this.result.status === RouteStatus.SUCCESS) {
      return $r('app.string.status_success');
    }
    if (this.result.status === RouteStatus.FALLBACK_BROWSER) {
      return $r('app.string.status_fallback_browser');
    }
    if (this.result.status === RouteStatus.PERMISSION_DENIED) {
      return $r('app.string.status_permission_denied');
    }
    return $r('app.string.status_failed');
  }

  private statusColor(): ResourceColor {
    if (this.result.status === RouteStatus.SUCCESS) {
      return $r('app.color.status_success');
    }
    if (this.result.status === RouteStatus.FALLBACK_BROWSER) {
      return $r('app.color.status_fallback');
    }
    return $r('app.color.status_failed');
  }

  private triggerLabel(): ResourceStr {
    if (this.result.trigger === RouteTriggerType.HEALTH_NOTIFICATION) {
      return $r('app.string.trigger_health_title');
    }
    if (this.result.trigger === RouteTriggerType.MESSAGE_NOTIFICATION) {
      return $r('app.string.trigger_message_title');
    }
    if (this.result.trigger === RouteTriggerType.CUSTOM_LINK) {
      return $r('app.string.trigger_link_title');
    }
    return $r('app.string.route_result_unknown_trigger');
  }

  @Builder
  detailRow(label: ResourceStr, value: ResourceStr) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize($r('app.float.detail_label_font_size'))
        .fontColor($r('app.color.subtitle_text'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(value)
        .fontSize($r('app.float.detail_value_font_size'))
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(ARC_ITEM_WIDTH)
    .alignItems(HorizontalAlign.Center)
    .padding($r('app.float.detail_row_padding'))
    .backgroundColor($r('app.color.trigger_item_background'))
    .borderRadius($r('app.float.trigger_item_corner_radius'))
  }

  build() {
    ArcList({ initialIndex: 0 }) {
      ArcListItem() {
        Text($r('app.string.route_result_page_title'))
          .width(ARC_ITEM_WIDTH)
          .fontSize($r('app.float.page_title_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
          .textAlign(TextAlign.Center)
      }

      ArcListItem() {
        Text(this.statusLabel())
          .width(ARC_ITEM_WIDTH)
          .fontSize($r('app.float.status_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.statusColor())
          .textAlign(TextAlign.Center)
      }

      ArcListItem() {
        this.detailRow($r('app.string.result_trigger_label'), this.triggerLabel())
      }
      ArcListItem() {
        this.detailRow($r('app.string.result_start_options_label'), this.result.startOptionsSummary)
      }
      ArcListItem() {
        this.detailRow($r('app.string.result_completion_label'), this.result.completionOutcome)
      }
      ArcListItem() {
        this.detailRow($r('app.string.result_ability_result_label'), this.result.abilityResultSummary)
      }
      ArcListItem() {
        this.detailRow($r('app.string.result_message_label'), this.result.message)
      }

      if (this.result.status === RouteStatus.FAILED) {
        ArcListItem() {
          Button($r('app.string.result_retry_button'), { type: ButtonType.Capsule })
            .width(ARC_ITEM_WIDTH)
            .backgroundColor($r('app.color.primary_button_background'))
            .fontColor($r('app.color.primary_button_text'))
            .onClick(() => this.pathStack.pop())
        }
      }

      ArcListItem() {
        Button($r('app.string.result_back_button'), { type: ButtonType.Capsule })
          .width(ARC_ITEM_WIDTH)
          .backgroundColor($r('app.color.secondary_button_background'))
          .fontColor($r('app.color.secondary_button_text'))
          .onClick(() => this.pathStack.pop())
      }
    }
    .space(LengthMetrics.resource($r('app.float.section_spacing')))
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}

/** NavDestination wrapper registered by RouteTriggerPage's navDestination builder. */
@Component
export struct RouteResultPageDestination {
  @Prop result: RouteResultData;

  build() {
    NavDestination() {
      RouteResultPage({ result: this.result })
    }
    .hideTitleBar(true)
  }
}
