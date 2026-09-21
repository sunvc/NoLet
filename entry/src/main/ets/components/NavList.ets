import { NavBottomSpacer, NavTopSpacer, TITLE_BAR_HEIGHT_FREE, TITLE_BOTTOM_GAP } from './NavSpacer';

export { TITLE_BAR_HEIGHT_MINI, TITLE_BAR_HEIGHT_FREE } from './NavSpacer';

/**
 * 沉浸式列表封装
 * 窗口全屏布局(setWindowLayoutFullScreen)下，首尾自动插入避让占位项：
 * 顶部 NavTopSpacer（状态栏 + 标题栏），底部 NavBottomSpacer（手势条 + 悬浮 TabBar）
 * immersive = false 时不插入占位项，交由系统安全区避让
 * 根页标题栏为 FREE 大标题用默认值；二级页传 titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0
 */
@ComponentV2
export struct NavList {
  @Param space: number = 10;
  @Param immersive: boolean = true;
  @Param titleHeight: number = TITLE_BAR_HEIGHT_FREE;
  @Param topGap: number = TITLE_BOTTOM_GAP;
  @Param bottomExtra: number = 76;
  @Param hPadding: number = 16;
  @Param scrollBarState: BarState = BarState.Off;
  // 可选外部控制器，不传时使用内部默认实例。
  // 页面需把同一实例传给 Navigation/NavDestination.bindToScrollable，
  // 修复弹簧回弹时 FREE 大标题卡在 mini 高度的问题；
  // 传入 ListScroller 子类还可调用 closeAllSwipeActions
  @Param scroller: Scroller | undefined = undefined;
  @BuilderParam content: () => void;

  private internalScroller: Scroller = new Scroller();

  build() {
    List({ space: this.space, scroller: this.scroller ?? this.internalScroller }) {
      if (this.immersive) {
        NavTopSpacer({ titleHeight: this.titleHeight, gap: this.topGap })
      }
      this.content()
      if (this.immersive) {
        NavBottomSpacer({ extra: this.bottomExtra })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: this.hPadding, right: this.hPadding })
    .scrollBar(this.scrollBarState)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }
}
