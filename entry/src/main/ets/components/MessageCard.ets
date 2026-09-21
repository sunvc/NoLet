import { Message } from '../model/Message';
import { uiState, UIState } from '../model/UIState';
import { messageLocator } from '../model/MessageLocator';
import { resByName } from '../tools/I18n';
import { common } from '@kit.AbilityKit';
import { AnimatorResult } from '@kit.ArkUI';
import { MarkdownBody } from './MarkdownBody';

// 卡片正文超过该高度(vp)时截断并显示「查看更多」（5 行 × 21vp 行高）
const BODY_CLIP_HEIGHT: number = 165;

@ComponentV2
export struct MessageCard {
  @Require @Param message: Message;
  // 监听智感握姿（miniOnRight）
  @Local ui: UIState = uiState;
  // 点击「查看更多」回调（全屏阅读完整内容）
  @Param onViewMore: (() => void) | null = null;
  // Markdown 正文自然高度(vp)，用于判断是否超过截断高度
  @Local bodyHeight: number = 0;
  // 未读竖条呼吸透明度（0.35 ↔ 1 循环）
  @Local breath: number = 1;
  // 呼吸动画器（挂载后播放，销毁时取消）
  private breathAnimator: AnimatorResult | null = null;

  aboutToAppear(): void {
    if (!this.message.read) {
      // 延迟到组件挂载后再启动，aboutToAppear 里直接启动动画会被丢弃
      setTimeout((): void => this.startBreath(), 50);
    }
  }

  aboutToDisappear(): void {
    this.breathAnimator?.cancel();
    this.breathAnimator = null;
  }

  // 同 id 推送覆盖可能把已读重置为未读：此时补启呼吸
  @Monitor('message.read')
  onReadChanged(): void {
    if (!this.message.read) {
      this.startBreath();
    }
  }

  // 未读绿条呼吸：1.1s 0.35 ↔ 1 永久交替（createAnimator 逐帧写透明度）
  private startBreath(): void {
    if (this.breathAnimator !== null) return;
    const animator: AnimatorResult = this.getUIContext().createAnimator({
      duration: 1100,
      delay: 0,
      easing: 'easeInOut',
      iterations: -1,
      fill: 'none',
      direction: 'alternate',
      begin: 0.35,
      end: 1
    });
    animator.onFrame = (value: number): void => {
      this.breath = value;
    };
    animator.play();
    this.breathAnimator = animator;
  }

  // 全量正文是否超过截断高度
  private hasMoreBody(): boolean {
    return this.message.body.length > 0 && this.bodyHeight > BODY_CLIP_HEIGHT + 2;
  }

  // 打开消息携带的链接（系统浏览器处理）
  private openUrl(url: string): void {
    if (!url) return;
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.startAbility({ action: 'ohos.want.action.viewData', uri: url })
        .catch((e: Error): void => console.error(`open url failed: ${e.message}`));
    } catch (e) {
      console.error(`open url failed: ${(e as Error).message}`);
    }
  }

  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  // url 行的点击覆盖层：整行单击跳走；Transparent 使长按穿透给文本复制
  @Builder
  urlTapLayer() {
    Row()
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .gesture(
        TapGesture()
          .onAction((): void => this.openUrl(this.message.url))
      )
  }

  // 左缘状态竖条：未读绿色（呼吸）、已读灰色，高度对齐标题行
  @Builder
  statusBar() {
    Row()
      .width(4)
      .height(18)
      .borderRadius(2)
      .backgroundColor(this.message.read
        ? $r('app.color.read_bar')
        : $r('app.color.unread_bar'))
      .opacity(this.message.read ? 1 : this.breath)
  }

  build() {
    // iOS 通知卡片结构：右侧内容列，左缘竖条表示已读/未读（灰/绿），所有文字左缘对齐
    Row() {
      Column() {
        // 标题 + 时间
        Row() {
          if (this.message.title) {
            Text(this.message.title)
              .fontSize(17)
              .fontWeight(600)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
              .copyOption(CopyOptions.LocalDevice)
          }

          Text(Message.timeText(this.message.createDate))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 8 })
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(8)
            .backgroundColor($r('app.color.bg_chip'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        if (this.message.body) {
          // 正文气泡：Markdown 渲染，超过 5 行高度由 MarkdownBody 内部裁剪
          Column() {
            MarkdownBody({
              text: this.message.body,
              maxHeight: BODY_CLIP_HEIGHT,
              onMeasured: (h: number): void => {
                this.bodyHeight = h;
              }
            })
          }
          .width('100%')
          .margin({ top: 8 })
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .borderRadius(10)
          .backgroundColor($r('app.color.bg_chip'))
        }

        if (this.message.url) {
          Row() {
            SymbolGlyph($r('sys.symbol.link'))
              .fontSize(12)
              .fontColor(['#1698CE'])
              .margin({ right: 4 })
            Text(this.message.url)
              .fontSize(13)
              .fontColor('#1698CE')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .copyOption(CopyOptions.LocalDevice)
              .textSelectable(TextSelectableMode.SELECTABLE_UNFOCUSABLE)
          }
          .width('100%')
          .margin({ top: 6 })
          // 整行可点：selectable Text 会吞掉落在文字上的点击（否则只剩图标可点）。
          // 透明覆盖层承接单击跳转，HitTestMode.Transparent 使长按穿透给 Text 弹出复制菜单
          .overlay(this.urlTapLayer)
        }

        // 超过截断高度才出现：胶囊跟随智感握姿贴左/贴右，拇指易触达。
        // 用显式 TapGesture 而非 onClick，避免冒泡触发搜索结果整卡的跳详情点击。
        if (this.hasMoreBody()) {
          Row() {
            Text(this.s('action_view_more'))
              .fontSize(12)
              .fontColor('#1698CE')
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor('#141698CE')
              .gesture(
                TapGesture()
                  .onAction((): void => {
                    if (this.onViewMore !== null) {
                      this.onViewMore();
                    }
                  })
              )
          }
          .width('100%')
          .margin({ top: 8 })
          .justifyContent(this.ui.miniOnRight ? FlexAlign.End : FlexAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 18, right: 14, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(14)
    // 定位高亮：整块绿色边框（5 秒后由 messageLocator 清除 highlightId）
    .border(messageLocator.highlightId === this.message.id
      ? { width: 2, color: '#34C759' }
      : { width: 0 })
    .clip(true)
    // 左缘竖条替代未读圆点：对齐标题行（top 14 + 2 微调），未读绿色、已读灰色
    .overlay(this.statusBar(), {
      align: Alignment.TopStart,
      offset: { x: 0, y: 16 }
    })
  }
}
