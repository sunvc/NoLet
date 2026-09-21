// 跨页面的瞬时 UI 状态（不持久化，冷启动必然重置）。
// 页面无 UI 实例要求，模块加载时创建，EntryAbility 在全屏布局下测量避让区后写入。
@ObservedV2
export class UIState {
  // 顶部状态栏高度(vp)
  @Trace statusBarHeight: number = 0;
  // 底部手势条/导航栏避让高度(vp)
  @Trace navIndicatorHeight: number = 0;

  // 当前是否右手握持：迷你页签/卡片内"查看更多"胶囊据此贴右（右手拇指区），左手置 false 贴左。默认右侧
  @Trace miniOnRight: boolean = true;

  // 底部悬浮页签是否可见：二级页/弹输入条时置 false。隐藏只动画改 barHeight(56→0)，宽度不缩
  @Trace tabBarVisible: boolean = true;

  // 关闭文本选区信号：每次递增时，所有 SelectionContainer 收起菜单并清除选中（切 Tab 时触发）
  @Trace dismissSelectionTick: number = 0;
}

export const uiState = new UIState();
