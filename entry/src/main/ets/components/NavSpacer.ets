import { uiState } from '../model/UIState';

// 标题栏官方高度(vp):MINI 模式 56;FREE 大标题 112
export const TITLE_BAR_HEIGHT_MINI: number = 56;
export const TITLE_BAR_HEIGHT_FREE: number = 112;
// 大标题与首条内容之间的设计留白
export const TITLE_BOTTOM_GAP: number = 0;

/**
 * List 顶部避让占位项
 * 状态栏高度 + 标题栏高度 + 设计留白。
 * 状态栏高度来自全局 uiState（EntryAbility 启动时测量并监听 avoidAreaChange），
 * 首帧即为正确高度，旋转/折叠实时跟随。
 */
@ComponentV2
export struct NavTopSpacer {
  @Param @Once titleHeight: number = TITLE_BAR_HEIGHT_FREE;
  @Param @Once gap: number = TITLE_BOTTOM_GAP;

  build() {
    ListItem() {
      Column()
        .width('100%')
        .height(uiState.statusBarHeight + this.titleHeight + this.gap)
    }
  }
}

/**
 * List 底部避让占位项
 * 底部系统安全区(手势条/导航栏) + 额外避让高度（悬浮胶囊 56vp 高 + 20vp 距底 = 76vp）
 */
@ComponentV2
export struct NavBottomSpacer {
  @Param @Once extra: number = 76;

  build() {
    ListItem() {
      Column()
        .width('100%')
        .height(uiState.navIndicatorHeight + this.extra)
    }
  }
}
