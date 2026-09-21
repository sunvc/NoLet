import { MessagesView } from './Messages'
import Settings from './Settings'
import { QuickView } from './Quick'
import { MessagesState } from '../model/MessagesState';
import { uiState } from '../model/UIState';
import { tabsController } from '../model/TabsController';
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { motion } from '@kit.MultimodalAwarenessKit';
import { Haptics } from '../tools/Haptics';


@Entry
@ComponentV2
struct Index {
  @Local currentIndex: number = 0;
  @Local state: MessagesState = MessagesState.shared;

  aboutToAppear(): void {
    // 智感握姿：维护 miniOnRight，供卡片内"查看更多"胶囊贴拇指侧（原生栏自身跟手走 adaptToHandedness）
    try {
      motion.on('holdingHandChanged', (status: motion.HoldingHandStatus): void => {
        if (status === motion.HoldingHandStatus.LEFT_HAND_HELD) {
          uiState.miniOnRight = false;
        } else if (status === motion.HoldingHandStatus.RIGHT_HAND_HELD) {
          uiState.miniOnRight = true;
        }
      });
    } catch (e) {
      console.error(`subscribe holdingHandChanged failed: ${(e as Error).message}`);
    }
  }

  build() {
    HdsTabs({
      controller: tabsController,
      index: this.currentIndex,
      barPosition: BarPosition.End
    }) {
      TabContent() {
        MessagesView()
      }
      .tabBar(this.tabItem(0, $r('sys.symbol.ellipsis_message_fill'), $r('app.string.tab_messages'), true))

      TabContent() {
        QuickView()
      }
      .tabBar(this.tabItem(1, $r('sys.symbol.paperplane_fill'), $r('app.string.tab_quick'), false))

      TabContent() {
        Settings()
      }
      .tabBar(this.tabItem(2, $r('sys.symbol.gearshape_fill'), $r('app.string.tab_settings'), false))
    }
    .width('100%')
    .height('100%')
    // 悬浮页签叠加在内容区之上；内容区不允许左右滑动切页，只能点页签切换
    .barOverlap(true)
    // 隐藏只改高度（宽度固定不缩），由子页面 animateTo 驱动 tabBarVisible
    .barHeight(uiState.tabBarVisible ? 56 : 0)
    .scrollable(false)
    .vertical(false)
    .barPosition(BarPosition.End)
    .barFloatingStyle({
      barWidth: { smallWidth: 372, mediumWidth: 372, largeWidth: 400 },
      barBottomMargin: (uiState.navIndicatorHeight > 0 ? uiState.navIndicatorHeight : 8) + 2,
      // 悬浮页签跟随握持手贴左/贴右（系统内部消费握姿）
      adaptToHandedness: true,
      // 沉浸光感材质：ADAPTIVE 按设备算力自动分档
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      }
    })
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onChange((index: number) => {
      this.currentIndex = index;
      // 切页时收起消息卡片可能正打开的文本选区菜单
      uiState.dismissSelectionTick++;
    })
  }

  // 单个页签项（上图标、下文字）；消息项带未读角标
  @Builder
  tabItem(targetIndex: number, icon: Resource, title: ResourceStr, withBadge: boolean) {
    Column({ space: 2 }) {
      if (withBadge) {
        Badge({
          count: this.state.unread,
          position: BadgePosition.RightTop,
          style: { badgeSize: 14, badgeColor: '#FF3B30' }
        }) {
          SymbolGlyph(icon)
            .fontSize(26)
            .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_OPACITY)
            .fontColor(this.tabColor(targetIndex))
        }
      } else {
        SymbolGlyph(icon)
          .fontSize(26)
          .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_OPACITY)
          .fontColor(this.tabColor(targetIndex))
      }
      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === targetIndex
          ? $r('sys.color.font_primary')
          : $r('app.color.text_secondary'))
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick((): void => {
      Haptics.success();
    })
  }

  private tabColor(targetIndex: number): ResourceColor[] {
    // 激活不用蓝色：跟随系统主文字色（浅色黑、深色白）
    const c: ResourceColor = this.currentIndex === targetIndex
      ? $r('sys.color.font_primary') : $r('app.color.text_secondary');
    return [c, c, c];
  }
}
