/**
 * UI for MockHealthAbility. Purely presentational - just echoes back the
 * want.parameters the router (LinkRouteResolver) sent it, via the
 * LocalStorage instance MockHealthAbility passed to windowStage.loadContent().
 *
 * Round-watch layout: content is short, so it is centered in the vertical
 * middle of the circle (the widest, least-clipped band) instead of pinned
 * to the top, and every line is center-aligned so wrapped text stays clear
 * of the curved edges.
 */
@Entry({ useSharedStorage: true })
@Component
struct MockHealthPage {
  @LocalStorageProp('page') page: string = '';
  @LocalStorageProp('source') source: string = '';

  build() {
    Column({ space: 12 }) {
      Text($r('app.string.mock_health_title'))
        .fontSize($r('app.float.page_title_font_size'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text($r('app.string.mock_health_page_label', this.page))
        .fontSize($r('app.float.detail_value_font_size'))
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text($r('app.string.mock_health_source_label', this.source))
        .fontSize($r('app.float.detail_value_font_size'))
        .fontColor($r('app.color.primary_text'))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text($r('app.string.mock_health_hint'))
        .fontSize($r('app.float.trigger_subtitle_font_size'))
        .fontColor($r('app.color.subtitle_text'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: $r('app.float.section_spacing') })
    }
    .width('100%')
    .height('100%')
    .padding($r('app.float.page_padding'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
