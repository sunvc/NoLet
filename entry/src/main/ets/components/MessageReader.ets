import { Message } from '../model/Message';
import { MarkdownBody } from './MarkdownBody';
import { uiState } from '../model/UIState';

// 消息整屏阅读层：作为 bindContentCover 内容使用。
// 标题/正文/链接完整展示，可滚动、可选择复制；右上 ✕ 关闭。宿主页面负责翻转显隐状态。
@ComponentV2
export struct MessageReader {
  @Require @Param message: Message;
  // 点击 ✕：由宿主页面关闭 bindContentCover
  @Require @Param onClose: () => void;

  build() {
    Column() {
      Row() {
        Blank()
        Button() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(15)
            .fontColor([$r('app.color.text_secondary')])
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor($r('app.color.bg_chip'))
        .onClick((): void => {
          this.onClose();
        })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: uiState.statusBarHeight + 10,
        bottom: 8
      })

      Scroll() {
        Column({ space: 12 }) {
          if (this.message.title) {
            Text(this.message.title)
              .fontSize(20)
              .fontWeight(700)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          if (this.message.body) {
            MarkdownBody({ text: this.message.body })
          }
          if (this.message.url) {
            Row() {
              SymbolGlyph($r('sys.symbol.link'))
                .fontSize(13)
                .fontColor(['#1698CE'])
                .margin({ right: 4 })
              Text(this.message.url)
                .fontSize(14)
                .fontColor('#1698CE')
            }
            .width('100%')
            .margin({ top: 4 })
          }
          Text(Message.timeText(this.message.createDate))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .margin({ top: 8 })
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({
          left: 20,
          right: 20,
          top: 8,
          bottom: (uiState.navIndicatorHeight > 0 ? uiState.navIndicatorHeight : 8) + 20
        })
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
