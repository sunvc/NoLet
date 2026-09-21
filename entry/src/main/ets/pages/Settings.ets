import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore } from '../store/AppStore';
import { uiState } from '../model/UIState';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList } from '../components/NavList';
import {
  HdsListItemCard, HdsNavigation, PrefixCustomBuilder, SuffixIcon
} from '@kit.UIDesignKit';
import { SoundSettingsView } from './SoundSettings';
import { DataSettingsView } from './DataSettings';
import { AboutView } from './About';
import { ServersView } from './Servers';
import { HistoryServersView } from './HistoryServers';
import { CryptoConfigsView } from './CryptoConfigs';
import { CryptoConfigEditView } from './CryptoConfigEdit';
import { MoreSettingsView } from './MoreSettings';
import { isPbLink, parseServerLink, parseCryptoLink, ServerLink } from '../tools/DeepLink';
import { resByName } from '../tools/I18n';
import { Haptics } from "../tools/Haptics";

@ComponentV2
export default struct Settings {
  @Local prop: AppStoreModel = appStore.getState();
  @Local stack: NavPathStack = new NavPathStack();
  // bindToScrollable 绑定用：修复弹簧回弹时 FREE 大标题卡在 mini 高度
  private listScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 二级页入栈/出栈时联动隐藏与恢复悬浮页签栏（只动画改高度，宽度不缩）
    this.stack.setInterception({
      willShow: (_from: NavDestinationContext | 'navBar', to: NavDestinationContext | 'navBar'): void => {
        this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, (): void => {
          uiState.tabBarVisible = to === 'navBar';
        });
      }
    });
    // 剪贴板里有 nolet://server 或 nolet://crypto 链接时，直接走对应添加/导入流程
    this.handleClipboardLink();
  }

  build() {
    HdsNavigation(this.stack) {
      // HDS 卡片自带 16vp 外边距，hPadding 设 0
      NavList({ space: 8, hPadding: 0, scroller: this.listScroller }) {
        this.sectionHeader($r('app.string.section_servers'))
        ListItem() {
          this.navCard($r('sys.symbol.wifi_router'), '#007AFF', $r('app.string.menu_servers'), '', 'servers')
        }

        this.sectionHeader($r('app.string.section_general'))
        ListItem() {
          this.navCard($r('sys.symbol.speaker_wave_2'), '#FF3B30', $r('app.string.menu_sound'), '', 'sound')
        }

        ListItem() {
          this.navCard($r('sys.symbol.archivebox'), '#FF9500', $r('app.string.menu_data'), '', 'data')
        }

        ListItem() {
          this.navCard($r('sys.symbol.bolt_shield'), '#007AFF', $r('app.string.menu_crypto'), '', 'crypto')
        }

        ListItem() {
          this.navCard($r('sys.symbol.gearshape'), '#8E8E93', $r('app.string.menu_more'), '', 'more')
        }

        this.sectionHeader($r('app.string.section_about'))
        ListItem() {
          this.navCard($r('sys.symbol.info_circle'), '#007AFF', $r('app.string.menu_about'), '', 'about')
        }
      }
    }
    .mode(NavigationMode.Auto)
    .bindToScrollable([this.listScroller])
    .titleBar(hdsTitleBar($r('app.string.tab_settings'), [
      {
        content: {
          icon: $r('sys.symbol.line_viewfinder'),
          action: (): void => {
            this.scanCode();
            Haptics.success();
          }
        }
      }
    ]))
    .navDestination(this.pageMap)
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  pageMap(name: string, param?: object) {
    if (name === 'sound') {
      SoundSettingsView()
    } else if (name === 'data') {
      DataSettingsView()
    } else if (name === 'about') {
      AboutView()
    } else if (name === 'servers') {
      // 扫码添加服务器时 param 携带预填的 url/key；注入路由栈用于打开历史服务器页
      ServersView({
        prefillUrl: this.linkField(param, 'url'),
        prefillKey: this.linkField(param, 'key'),
        stack: this.stack
      })
    } else if (name === 'historyServers') {
      HistoryServersView()
    } else if (name === 'crypto') {
      // 扫码导入配置时 param 携带 Domap 混淆串
      CryptoConfigsView({ stack: this.stack, importPayload: String(param ?? '') })
    } else if (name === 'cryptoEdit') {
      CryptoConfigEditView({ configId: String(param ?? ''), stack: this.stack })
    } else if (name === 'more') {
      MoreSettingsView()
    }
  }

  // 取出 pushPath 传入的 ServerLink 字段（@Builder 内不能写局部变量）
  private linkField(param: object | undefined, field: string): string {
    const link: ServerLink | undefined = param as ServerLink | undefined;
    if (!link) {
      return '';
    }
    return field === 'key' ? link.key : link.url;
  }

  // 分组标题：小号灰色，与卡片左缘对齐
  @Builder
  sectionHeader(title: ResourceStr) {
    ListItem() {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 14,
          bottom: 2
        })
    }
  }

  // 跳转卡片：左侧彩色圆角图标，B 区自定义「标题 + 右侧值 + 箭头」，保持原样式。
  // 设备 HDS 版本无 SuffixTextAndArrow，且 C 区 customBuilder 不支持容器节点，故整体放在 B 区。
  @Builder
  navCard(icon: Resource, color: string, label: ResourceStr, value: string, route: string) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => {
        this.iconTile(icon, color);
      }),
      textItem: {
        customBuilder: (): void => {
          this.cardText(label, value);
        }
      },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => this.stack.pushPath({ name: route })
    })
  }

  // B 区内容：标题 +（可选）右侧值 + 箭头
  @Builder
  cardText(label: ResourceStr, value: string) {
    Row() {
      Text(label)
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      if (value) {
        Text(value)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 180 })
          .margin({ right: 6 })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 左侧彩色圆角方块图标
  @Builder
  iconTile(icon: Resource, color: string) {
    Stack() {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor([Color.White])
    }
    .width(30)
    .height(30)
    .borderRadius(8)
    .backgroundColor(color)
  }

  // 扫码结果 / 剪贴板内容统一处理：nolet://server 链接跳服务器页走添加流程，
  // 看起来是 nolet:// 但解析失败提示无效，其他文本复制到剪贴板
  handleScannedValue(value: string): void {
    const link: ServerLink | null = parseServerLink(value);
    if (link !== null) {
      this.stack.pushPath({ name: 'servers', param: link });
      return;
    }
    const cryptoPayload: string | null = parseCryptoLink(value);
    if (cryptoPayload !== null) {
      this.stack.pushPath({ name: 'crypto', param: cryptoPayload });
      return;
    }
    if (isPbLink(value)) {
      this.scanToast(this.s('invalid_server_qr'));
      return;
    }
    this.copy(value);
    this.scanToast(this.s('copied_prefix', value));
  }

  // 拉起系统扫码页：识别结果与剪贴板走同一套处理逻辑
  async scanCode(): Promise<void> {
    const ctx: common.Context = this.getUIContext().getHostContext() as common.Context;
    try {
      const result = await scanBarcode.startScanForResult(ctx, {
        scanTypes: [scanCore.ScanType.ALL]
      });
      this.handleScannedValue(result.originalValue);
    } catch (e) {
      const err = e as BusinessError;
      // 用户取消扫码（13000001）不提示
      if (err.code !== 13000001) {
        this.scanToast(this.s('scan_failed', err.message));
      }
    }
  }

  // 读取剪贴板：匹配 nolet://server / nolet://crypto 后先弹确认框，
  // 用户确认才跳转对应页面并清空剪贴板；取消则保留剪贴板不跳转
  async handleClipboardLink(): Promise<boolean> {
    let text: string = '';
    try {
      const data = await pasteboard.getSystemPasteboard().getData();
      text = (data.getPrimaryText() ?? '').trim();
    } catch {
      return false;
    }
    let route: string = '';
    let param: Object | undefined;
    const link: ServerLink | null = parseServerLink(text);
    if (link !== null) {
      route = 'servers';
      param = link;
    } else {
      const cryptoPayload: string | null = parseCryptoLink(text);
      if (cryptoPayload !== null) {
        route = 'crypto';
        param = cryptoPayload;
      }
    }
    if (!route) return false;

    const confirmed: boolean = await this.confirmClipboardLink(route);
    if (!confirmed) return false;

    this.stack.pushPath({ name: route, param });
    try {
      await pasteboard.getSystemPasteboard().clearData();
    } catch (e) {
      hilog.error(0x0000, 'Settings', `clear pasteboard failed: ${(e as BusinessError).message}`);
    }
    return true;
  }

  // 口令确认弹窗：确认返回 true，取消或异常返回 false
  private async confirmClipboardLink(route: string): Promise<boolean> {
    try {
      const result: promptAction.ShowDialogSuccessResponse =
        await this.getUIContext().getPromptAction().showDialog({
          title: this.s('clipboard_link_title'),
          message: route === 'servers'
            ? this.s('clipboard_server_message')
            : this.s('clipboard_crypto_message'),
          buttons: [
            { text: this.s('action_cancel'), color: '#8E8E93' },
            { text: this.s('action_ok'), color: '#007AFF' }
          ]
        });
      return result.index === 1;
    } catch {
      return false;
    }
  }

  // 带占位符的动态文案取当前语言资源
  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  private scanToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({
      message,
      duration: 2000,
      showMode: promptAction.ToastShowMode.DEFAULT,
      bottom: 80
    });
  }

  copy(content: string): void {
    const pasteData: pasteboard.PasteData =
      pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
    pasteboard.getSystemPasteboard().setData(pasteData);
  }
}
