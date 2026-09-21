import { Markdown, MarkdownController, MdCallback } from '@luvi/lv-markdown-in';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { resByName } from '../tools/I18n';

// Markdown 正文渲染封装（@luvi/lv-markdown-in）。
// - 卡片场景传 maxHeight（vp）：Markdown 解析完成后若超过该高度，用固定高度裁剪显示前几行，
//   配合外部「查看更多」进全屏；裁剪时关闭懒渲染，保证裁剪窗口内内容完整
// - 全屏场景不传 maxHeight：自然完整高度，由外层 Scroll 滚动
// - onMeasured 回传正文自然高度(vp)，供调用方判断是否需要「查看更多」
@ComponentV2
export struct MarkdownBody {
  @Require @Param text: string = '';
  // 裁剪高度(vp)；null 表示完整展示
  @Param maxHeight: number | null = null;
  @Param onMeasured: ((heightVp: number) => void) | null = null;

  // Markdown 在 Worker 中异步解析，只有 complete 后的高度才是自然高度
  @Local renderReady: boolean = false;
  @Local naturalH: number = 0;

  private controller: MarkdownController = new MarkdownController();

  aboutToAppear(): void {
    const dark: boolean = this.isDarkMode();
    this.controller
      .setTextColor($r('app.color.text_primary'))
      .setTextSize(15)
      .setTextLineHeight(21)
      // 消息正文中的标题保持紧凑层级，不喧宾夺主
      .setTitleColor($r('app.color.text_primary'))
      .setTitleSize([17, 16, 16, 15, 15, 15])
      .setTitleLineHeight([24, 23, 23, 22, 22, 22])
      .setHyperlinkTextColor('#1698CE')
      .setHyperlinkUnderlineState(true)
      // 拦截超链接默认跳转：自行用系统浏览器打开，return true 阻止库默认行为
      .setHyperlinkClickListener((title: string, src: string): boolean => {
        this.openLink(title, src);
        return true;
      })
      // 行内代码
      .setInlineCodeColor($r('app.color.text_primary'))
      .setInlineCodeBackgroundColor($r('app.color.bg_chip'))
      .setInlineCodeBackgroundRadius(6)
      // 引用块
      .setQuoteTextColor($r('app.color.text_secondary'))
      .setQuoteBackgroundColor($r('app.color.bg_chip'))
      .setQuoteBorderColor('#1698CE')
      .setCodeBlockTheme(dark ? 'dark' : 'light')
      // 关闭懒渲染：卡片裁剪时必须把前几行全部布局出来，否则虚拟列表在裁剪区内是空白
      .setLazyRender(false)
      // 库自带跨 Text 选择，复制回调里自行写剪贴板并提示（v3.1 起内置复制已移除）
      .setTextSelectionEnable(true)
      .setTextSelectionCopyListener((value: string): void => {
        this.copyText(value);
      });
    // 块级元素间距收紧（消息卡片内更紧凑）；该接口返回 void，不能参与链式调用
    this.controller.setBlockSpacing(4);
  }

  private isDarkMode(): boolean {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return ctx.config?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private copyText(value: string): void {
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, value);
    pasteboard.getSystemPasteboard().setData(data);
    const ctx = this.getUIContext().getHostContext() as common.Context;
    this.getUIContext().getPromptAction().showToast({
      message: resByName(ctx, 'copy_success'),
      duration: 2000,
      showMode: promptAction.ToastShowMode.DEFAULT,
      bottom: 80
    });
  }

  // 超链接点击：交系统按 URI 处理（http(s) 拉起浏览器）。src 为空或无法处理时静默失败
  private openLink(title: string, src: string): void {
    console.info(`Markdown link tapped: title=${title} src=${src}`);
    if (!src) {
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    ctx.startAbility({ action: 'ohos.want.action.viewData', uri: src })
      .catch((e: BusinessError): void => {
        console.error(`open markdown link failed: ${e.code} ${e.message}`);
      });
  }

  // 是否处于裁剪态：仅在解析完成、且自然高度确实超过阈值后裁剪
  private isClipped(): boolean {
    return this.maxHeight !== null && this.renderReady && this.naturalH > this.maxHeight + 2;
  }

  build() {
    Column() {
      Markdown({
        text: this.text,
        controller: this.controller,
        mode: 'text',
        callback: {
          complete: (): void => {
            // Worker 解析渲染完成，下一帧 onAreaChange 上报的高度即为自然高度
            this.renderReady = true;
          },
          fail: (code: number, message: string): void => {
            console.error(`Markdown render fail: ${code} ${message}`);
          }
        } as MdCallback
      })
        .width('100%')
        .onAreaChange((_oldArea: Area, newArea: Area): void => {
          // 已进入裁剪态时上报的是被固定后的高度（=maxHeight），不能回写 naturalH，否则状态来回闪烁
          if (this.isClipped()) return;
          const h: number = this.getUIContext().px2vp(Number(newArea.height));
          if (h > 0 && Math.abs(h - this.naturalH) > 0.5) {
            this.naturalH = h;
            if (this.onMeasured !== null) {
              this.onMeasured(h);
            }
          }
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    // 裁剪态用确定高度（不能用 maxHeight 约束：内部容器可能自己消化溢出而不被裁剪）
    .height(this.isClipped() ? (this.maxHeight ?? 0) : undefined)
    .clip(true)
    // 裁剪预览态不拦截触摸：垂直滚动/左右滑操作交给外层 ListItem；选择复制进全屏
    .hitTestBehavior(this.isClipped() ? HitTestMode.None : HitTestMode.Default)
  }
}
