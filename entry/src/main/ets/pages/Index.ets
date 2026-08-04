import { common } from '@kit.AbilityKit';
import { ArcList, ArcListAttribute, ArcListItem, ArcListItemAttribute, LengthMetrics } from '@kit.ArkUI';
import { AbilityLaunchService } from '../service/AbilityLaunchService';
import { RouteResultData, RouteSettings, RouteTriggerType } from '../model/RouteModels';
import { RouteResultPageDestination } from './RouteResultPage';

/**
 * Width every ArcListItem's content is rendered at, leaving a left/right
 * gutter so cards and text stay clear of ArcList's own curved edge/scroll
 * indicator instead of touching it.
 */
const ARC_ITEM_WIDTH = '82%';

/** One row on the trigger list. */
interface TriggerItem {
  type: RouteTriggerType;
  title: ResourceStr;
  subtitle: ResourceStr;
}

/**
 * RouteTriggerPage: lists the mock incoming triggers (FR-01) and the
 * in-app settings that feed StartOptionsBuilder / OpenLinkOptions. Tapping a
 * trigger resolves + launches it via AbilityLaunchService, then hands the
 * outcome to RouteResultPage.
 *
 * Round-watch layout: everything - the title, the trigger cards and the
 * settings toggles - lives inside a single full-screen ArcList so the
 * physical/digital crown scrolls the whole page and ArcListItem's built-in
 * autoScale fades rows out near the curved top/bottom edge instead of
 * letting them clip against the bezel.
 */
@Entry
@Component
struct RouteTriggerPage {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  @State settings: RouteSettings = new RouteSettings();
  @State isLaunching: boolean = false;

  private triggers: TriggerItem[] = [
    {
      type: RouteTriggerType.HEALTH_NOTIFICATION,
      title: $r('app.string.trigger_health_title'),
      subtitle: $r('app.string.trigger_health_subtitle')
    },
    {
      type: RouteTriggerType.MESSAGE_NOTIFICATION,
      title: $r('app.string.trigger_message_title'),
      subtitle: $r('app.string.trigger_message_subtitle')
    },
    {
      type: RouteTriggerType.CUSTOM_LINK,
      title: $r('app.string.trigger_link_title'),
      subtitle: $r('app.string.trigger_link_subtitle')
    }
  ];

  private async handleTriggerTap(type: RouteTriggerType): Promise<void> {
    if (this.isLaunching) {
      return;
    }
    this.isLaunching = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const service = new AbilityLaunchService(context);
      const result: RouteResultData = await service.launch(type, this.settings);
      this.pathStack.pushPathByName('RouteResultPage', result);
    } finally {
      this.isLaunching = false;
    }
  }

  @Builder
  triggerRow(item: TriggerItem) {
    Column({ space: 2 }) {
      Text(item.title)
        .fontSize($r('app.float.trigger_title_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(item.subtitle)
        .fontSize($r('app.float.trigger_subtitle_font_size'))
        .fontColor($r('app.color.subtitle_text'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(ARC_ITEM_WIDTH)
    .alignItems(HorizontalAlign.Center)
    .padding($r('app.float.trigger_item_padding'))
    .backgroundColor($r('app.color.trigger_item_background'))
    .borderRadius($r('app.float.trigger_item_corner_radius'))
    .onClick(() => this.handleTriggerTap(item.type))
  }

  @Builder
  settingToggle(label: ResourceStr, isOn: boolean, onToggle: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize($r('app.float.setting_label_font_size'))
        .fontColor($r('app.color.primary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn })
        .onChange(onToggle)
    }
    .width(ARC_ITEM_WIDTH)
  }

  build() {
    Navigation(this.pathStack) {
      this.triggerPageContent()
    }
    .navDestination(this.buildDestination)
    .mode(NavigationMode.Stack)
    .hideToolBar(true)
    .hideTitleBar(true)
  }

  @Builder
  triggerPageContent() {
    // The title lives as the first ArcListItem (instead of a fixed sibling
    // above the list) so ArcList owns the full round canvas - giving it a
    // shorter box than the whole screen throws off its arc curvature math
    // and made rows look cut off.
    ArcList({ initialIndex: 0 }) {
      ArcListItem() {
        Text($r('app.string.route_trigger_page_title'))
          .width(ARC_ITEM_WIDTH)
          .fontSize($r('app.float.page_title_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
          .textAlign(TextAlign.Center)
      }

      ForEach(this.triggers, (item: TriggerItem) => {
        ArcListItem() {
          this.triggerRow(item)
        }
      }, (item: TriggerItem) => item.type)

      ArcListItem() {
        Text($r('app.string.settings_section_title'))
          .width(ARC_ITEM_WIDTH)
          .fontSize($r('app.float.section_title_font_size'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.primary_text'))
          .textAlign(TextAlign.Center)
      }

      ArcListItem() {
        this.settingToggle($r('app.string.setting_with_animation'), this.settings.withAnimation, (value: boolean) => {
          this.settings.withAnimation = value;
        })
      }

      ArcListItem() {
        this.settingToggle($r('app.string.setting_fullscreen_window'), this.settings.useFullscreenWindowMode, (value: boolean) => {
          this.settings.useFullscreenWindowMode = value;
        })
      }

      ArcListItem() {
        this.settingToggle($r('app.string.setting_app_linking_only'), this.settings.appLinkingOnly, (value: boolean) => {
          this.settings.appLinkingOnly = value;
        })
      }

      ArcListItem() {
        this.settingToggle($r('app.string.setting_hide_failure_dialog'), this.settings.hideFailureTipDialog, (value: boolean) => {
          this.settings.hideFailureTipDialog = value;
        })
      }

      if (this.isLaunching) {
        ArcListItem() {
          LoadingProgress()
            .width($r('app.float.loading_indicator_size'))
            .height($r('app.float.loading_indicator_size'))
        }
      }
    }
    .space(LengthMetrics.resource($r('app.float.section_spacing')))
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  buildDestination(name: string, param: Object) {
    if (name === 'RouteResultPage') {
      RouteResultPageDestination({ result: param as RouteResultData });
    }
  }
}
