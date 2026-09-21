import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { Haptics } from '../tools/Haptics';
import { common } from '@kit.AbilityKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { CryptoAlgorithm, CryptoConfig, CryptoConfigFactory } from '../model/CryptoConfig';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { resByName } from '../tools/I18n';
import { isPbLink, parseCryptoLink } from '../tools/DeepLink';

// 对应 iOS ChangeCryptoConfigView：编辑单个签名密钥配置。
// 支持粘贴 Domap 混淆配置串导入、切换算法、限长输入 KEY、随机生成。
@ComponentV2
export struct CryptoConfigEditView {
  @Require @Param configId: string;
  @Require @Param stack: NavPathStack;
  @Local prop: AppStoreModel = appStore.getState();
  @Local algorithm: number = CryptoAlgorithm.AES256;
  @Local keyText: string = '';
  @Local iv: string = '';
  @Local importText: string = '';
  @Local importOk: boolean = false;
  private scroller: ListScroller = new ListScroller();

  aboutToAppear(): void {
    const target = this.prop.cryptoConfigs.find((c): boolean => c.id === this.configId);
    if (target) {
      this.algorithm = target.algorithm;
      this.keyText = target.key;
      this.iv = target.iv;
    }
  }

  randomKey(): void {
    this.keyText = CryptoConfigFactory.randomString(this.algorithm);
    if (!this.iv) this.iv = CryptoConfigFactory.randomString(16);
    this.importOk = false;
    Haptics.success();
  }

  parseImport(): void {
    // 支持粘贴 nolet://crypto?text=<混淆串> 深链或裸混淆串
    let payload: string = this.importText.trim();
    if (isPbLink(payload)) {
      const linked: string | null = parseCryptoLink(payload);
      if (linked === null) {
        this.importOk = false;
        this.toast(this.s('import_bad'));
        return;
      }
      payload = linked;
    }
    const parsed = CryptoConfigFactory.deobfuscate(payload);
    if (parsed === null) {
      this.importOk = false;
      this.toast(this.s('import_bad'));
      return;
    }
    this.algorithm = parsed.algorithm;
    this.keyText = parsed.key;
    this.iv = parsed.iv;
    this.importOk = true;
    this.toast(this.s('import_ok'));
  }

  copyKey(): void {
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.keyText);
    pasteboard.getSystemPasteboard().setData(data);
    this.toast(this.s('key_copied'));
  }

  save(): void {
    // 兜底：系统内置保留项不允许修改（正常情况下列表页不会让其进入此页）
    const current = this.prop.cryptoConfigs.find((c: CryptoConfig): boolean => c.id === this.configId);
    if (current && current.builtin) {
      this.toast(this.s('err_builtin_edit'));
      return;
    }
    if (this.keyText.length !== this.algorithm) {
      this.toast(this.s('key_length_hint', this.algorithm));
      return;
    }
    if (!this.iv) {
      this.iv = CryptoConfigFactory.randomString(16);
    }
    appStore.dispatch(AppActions.updateCryptoConfig({
      id: this.configId,
      algorithm: this.algorithm,
      mode: 'GCM',
      key: this.keyText,
      iv: this.iv,
    }));
    this.stack.pop();
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

  @Builder
  sectionTitle(title: ResourceStr, trailing: string = '') {
    Row() {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      if (trailing) {
        Text(trailing)
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .padding({ left: 4, top: 14, bottom: 6 })
  }

  build() {
    HdsNavDestination() {
      NavList({ space: 8, hPadding: 16, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
        scroller: this.scroller }) {
        // 导入配置
        ListItem() {
          this.sectionTitle($r('app.string.section_import'))
        }
        .padding(0)
        ListItem() {
          Column({ space: 10 }) {
            TextArea({ placeholder: $r('app.string.import_placeholder'), text: $$this.importText })
              .height(96)
              .backgroundColor($r('app.color.bg_chip'))
              .borderRadius(10)
              .padding(12)
              .borderWidth(this.importOk ? 1.5 : 0)
              .borderColor(this.importOk ? '#34C759' : Color.Transparent)
            Button($r('app.string.import_button'))
              .width('100%')
              .height(42)
              .borderRadius(10)
              .backgroundColor($r('app.color.bg_chip'))
              .fontColor($r('app.color.text_primary'))
              .fontSize(15)
              .onClick((): void => this.parseImport())
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius(16)
        }
        .padding(0)

        // 加密算法
        ListItem() {
          this.sectionTitle($r('app.string.section_algorithm'))
        }
        .padding(0)
        ListItem() {
          Select([
            { value: this.s('alg_aes128') },
            { value: this.s('alg_aes192') },
            { value: this.s('alg_aes256') }
          ])
            .selected(CryptoAlgorithm.ALL.indexOf(this.algorithm))
            .value(CryptoAlgorithm.algName(this.algorithm))
            .width('100%')
            .height(48)
            .backgroundColor($r('app.color.bg_card'))
            .borderRadius(16)
            .onSelect((idx: number): void => {
              const len: number = CryptoAlgorithm.ALL[idx];
              this.algorithm = len;
              // 与 iOS 一致：切换算法截断超长 KEY
              this.keyText = this.keyText.substring(0, len);
            })
        }
        .padding(0)

        // KEY
        ListItem() {
          Row() {
            Text('KEY')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
            Text(this.s('key_needed', Math.max(0, this.algorithm - this.keyText.length)))
              .fontSize(13)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ right: 12 })
            Text($r('app.string.random_generate'))
              .fontSize(13)
              .fontColor('#34C759')
              .onClick((): void => this.randomKey())
          }
          .width('100%')
          .padding({ left: 4, top: 14, bottom: 6 })
        }
        .padding(0)
        ListItem() {
          Row({ space: 10 }) {
            TextInput({ text: $$this.keyText })
              .layoutWeight(1)
              .height(48)
              .backgroundColor($r('app.color.bg_chip'))
              .borderRadius(10)
              .padding({ left: 14, right: 14 })
              .maxLength(this.algorithm)
              .fontColor(this.keyText.length === this.algorithm
                ? $r('app.color.text_primary') : '#FF3B30')
            Button() {
              SymbolGlyph($r('sys.symbol.doc'))
                .fontSize(20)
                .fontColor([$r('app.color.text_primary')])
            }
            .width(48)
            .height(48)
            .backgroundColor($r('app.color.bg_chip'))
            .borderRadius(10)
            .onClick((): void => this.copyKey())
          }
          .width('100%')
          // 卡片衬底：浅色下 bg_chip(#F1F1F1) 与页面背景同色，需落在 bg_card 白底上才有分层
          .padding(12)
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius(16)
        }
        .padding(0)

        ListItem() {
          Button($r('app.string.action_save'))
            .width('100%')
            .height(48)
            .borderRadius(10)
            .backgroundColor('#1698CE')
            .fontColor(Color.White)
            .fontSize(16)
            .margin({ top: 16 })
            .onClick((): void => this.save())
        }
        .padding(0)
      }
    }
    .titleBar(hdsTitleBar($r('app.string.title_edit_crypto')))
    .bindToScrollable([this.scroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
