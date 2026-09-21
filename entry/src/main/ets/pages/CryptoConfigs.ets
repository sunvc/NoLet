import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { Haptics } from '../tools/Haptics';
import { common } from '@kit.AbilityKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { CryptoConfig, CryptoAlgorithm, CryptoConfigFactory } from '../model/CryptoConfig';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { HdsNavDestination, HdsListItemCard, PrefixCustomBuilder, SuffixCustomBuilder } from '@kit.UIDesignKit';
import { resByName } from '../tools/I18n';
import { buildCryptoLink } from '../tools/DeepLink';

// 序号色块底色板：iOS 系统色风格，超出长度循环
const INDEX_COLORS: string[] =
  ['#5856D6', '#FF9500', '#FF3B30', '#34C759', '#AF52DE',
    '#FF2D55', '#5AC8FA', '#FFCC00', '#007AFF', '#8E8E93'];

// 对应 iOS CryptoConfigListView：签名密钥配置列表。
// 右上角 + 直接新增随机配置；点击卡片进编辑；右滑复制配置串，左滑删除（删空补内置默认）。
// 系统内置项固定渲染在最前且不参与拖动；其余配置长按拖动排序（ForEach.onMove）。
@ComponentV2
export struct CryptoConfigsView {
  @Require @Param stack: NavPathStack;
  // 扫码/剪贴板识别 nolet://crypto 链接时携带的 Domap 混淆串，进入页面自动导入
  @Param importPayload: string = '';
  @Local prop: AppStoreModel = appStore.getState();
  private scroller: ListScroller = new ListScroller();

  aboutToAppear(): void {
    if (!this.importPayload) return;
    const parsed: CryptoConfig | null = CryptoConfigFactory.deobfuscate(this.importPayload);
    if (parsed === null) {
      this.toast(this.s('import_bad'));
      return;
    }
    // 列表数据唯一：模式+KEY+IV 完全一致则不重复新增
    if (CryptoConfigFactory.existsLike(this.prop.cryptoConfigs, parsed)) {
      Haptics.warning();
      this.toast(this.s('config_exists'));
      setTimeout((): void => { this.stack.pop(); }, 600);
      return;
    }
    appStore.dispatch(AppActions.addCryptoConfig(parsed));
    Haptics.success();
    this.toast(this.s('import_ok'));
    // 导入成功直接关闭本页返回；延迟一拍等 push 转场完成，避免与入场冲突
    setTimeout((): void => { this.stack.pop(); }, 600);
  }

  addConfig(): void {
    appStore.dispatch(AppActions.addCryptoConfig(CryptoConfigFactory.newRandomConfig()));
    Haptics.success();
  }

  // 系统内置配置（始终在最前，不可拖动/删除）
  private builtinConfigs(): CryptoConfig[] {
    return this.prop.cryptoConfigs.filter((c: CryptoConfig): boolean => c.builtin);
  }

  // 用户自定义配置（可拖动排序）
  private customConfigs(): CryptoConfig[] {
    return this.prop.cryptoConfigs.filter((c: CryptoConfig): boolean => !c.builtin);
  }

  removeConfig(c: CryptoConfig): void {
    // 系统内置保留项不可删除（正常路径下删除滑动按钮也不会露出）
    if (c.builtin) {
      this.toast(this.s('err_builtin_delete'));
      return;
    }
    appStore.dispatch(AppActions.removeCryptoConfig(c.id));
    if (this.prop.cryptoConfigs.length === 0) {
      appStore.dispatch(AppActions.addCryptoConfig(CryptoConfigFactory.defaultConfig()));
    }
  }

  copyConfig(c: CryptoConfig): void {
    // 系统内置配置不可复制
    if (c.builtin) {
      this.toast(this.s('err_builtin_copy'));
      return;
    }
    const text: string | null = CryptoConfigFactory.obfuscate(c);
    if (text === null) {
      this.toast(this.s('import_bad'));
      return;
    }
    // 复制为深链格式 nolet://crypto?text=<混淆串>（与 iOS 一致）
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, buildCryptoLink(text));
    pasteboard.getSystemPasteboard().setData(data);
    // 收起滑动操作按钮，避免停留在展开态
    this.scroller.closeAllSwipeActions();
    this.toast(this.s('config_copied'));
  }

  // ForEach.onMove：from/to 是用户配置子集内下标，映射成 cryptoConfigs 全局下标
  private onCustomMove(from: number, to: number): void {
    const custom: CryptoConfig[] = this.customConfigs();
    if (from === to || from < 0 || to < 0 || from >= custom.length || to >= custom.length) {
      return;
    }
    const all: CryptoConfig[] = this.prop.cryptoConfigs;
    const fromId: string = custom[from].id;
    const toId: string = custom[to].id;
    let gFrom: number = -1;
    let gTo: number = -1;
    for (let i = 0; i < all.length; i++) {
      if (all[i].id === fromId) gFrom = i;
      if (all[i].id === toId) gTo = i;
    }
    if (gFrom >= 1 && gTo >= 1) {
      appStore.dispatch(AppActions.reorderCryptoConfig(gFrom, gTo));
    }
  }

  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({
      message,
      duration: 2000,
      showMode: promptAction.ToastShowMode.DEFAULT,
      bottom: 80
    });
  }

  private maskKey(key: string): string {
    if (key.length <= 9) return `***${key}`;
    return key.substring(0, 3) + '***' + key.substring(key.length - 5);
  }

  // 序号从 00 起（系统内置固定为 00），两位补零
  private indexLabel(globalIndex: number): string {
    return globalIndex < 10 ? `0${globalIndex}` : `${globalIndex}`;
  }

  // 序号色块底色：按下标循环取色（00 系统内置固定取第一色）
  private indexColor(globalIndex: number): string {
    return INDEX_COLORS[globalIndex % INDEX_COLORS.length];
  }

  // 左侧序号（彩色圆角色块 + 白色数字）
  @Builder
  configIndex(c: CryptoConfig) {
    Text(this.indexLabel(this.prop.cryptoConfigs.indexOf(c)))
      .fontSize(14)
      .fontWeight(700)
      .fontColor(Color.White)
      .textAlign(TextAlign.Center)
      .width(30)
      .height(30)
      .borderRadius(8)
      .backgroundColor(this.indexColor(this.prop.cryptoConfigs.indexOf(c)))
  }

  // 右侧「系统内置」标签：彩色圆角色块，底色与 00 序号块一致。
  // 直接放 Text 会填满 suffix 区贴到卡片右边缘，用 Row 包一层让其按内容收缩
  @Builder
  builtinBadge() {
    Row() {
      Text($r('app.string.builtin_tag'))
        .fontSize(12)
        .fontWeight(600)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .padding({ left: 9, right: 9, top: 4, bottom: 4 })
        .borderRadius(7)
        .backgroundColor(this.indexColor(0))
        .margin({right: 19})
    }



  }

  @Builder
  configCard(c: CryptoConfig) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.configIndex(c); }),
      textItem: {
        primaryText: { text: `${CryptoAlgorithm.algName(c.algorithm)}-${c.mode}` },
        secondaryText: { text: `KEY: ${this.maskKey(c.key)}` }
      },
      suffixItem: c.builtin
        ? new SuffixCustomBuilder((): void => { this.builtinBadge(); })
        : undefined,
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => {
        if (c.builtin) {
          this.toast(this.s('err_builtin_edit'));
          return;
        }
        this.stack.pushPath({ name: 'cryptoEdit', param: c.id });
      }
    })
  }

  @Builder
  swipeButton(label: string, color: string, mLeft: number, mRight: number, action: () => void) {
    Button(label)
      .backgroundColor(color)
      .fontColor(Color.White)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .margin({ left: mLeft, right: mRight })
      .onClick(action)
  }

  // 单个配置行：内置无滑动操作（不可复制/删除），自定义可复制可删除
  @Builder
  configRow(c: CryptoConfig) {
    ListItem() {
      Column() {
        this.configCard(c)
      }
    }
    .swipeAction(c.builtin
      ? {}
      : {
        start: this.swipeButton(this.s('action_copy_string'), '#FF9500', 0, 10,
          (): void => this.copyConfig(c)),
        end: this.swipeButton(this.s('action_delete'), '#FF3B30', 10, 0,
          (): void => this.removeConfig(c))
      })
  }

  @Builder
  emptyTip() {
    Column() {
      Blank()
      Text($r('app.string.empty_crypto'))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
      Blank()
    }
    .width('100%')
    .height('100%')
  }

  build() {
    HdsNavDestination() {
      if (this.prop.cryptoConfigs.length === 0) {
        this.emptyTip()
      } else {
        NavList({ space: 8, hPadding: 0, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
          scroller: this.scroller }) {
          // 系统内置：独立 ForEach 固定在最前，不挂 onMove，物理上无法被拖入换位
          ForEach(this.builtinConfigs(), (c: CryptoConfig) => {
            this.configRow(c)
          }, (c: CryptoConfig): string => c.id)
          // 用户配置：长按拖动排序
          ForEach(this.customConfigs(), (c: CryptoConfig) => {
            this.configRow(c)
          }, (c: CryptoConfig): string => c.id)
            .onMove((from: number, to: number): void => {
              this.onCustomMove(from, to);
            })
        }
      }
    }
    .titleBar(hdsTitleBar($r('app.string.title_crypto'), [
      {
        content: {
          icon: $r('sys.symbol.plus'),
          action: (): void => { this.addConfig(); }
        }
      }
    ]))
    .bindToScrollable([this.scroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
