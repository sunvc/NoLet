import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { Haptics } from '../tools/Haptics';
import { common } from '@kit.AbilityKit';
import { messageStore } from '../model/DBTools';
import { MessagesState } from '../model/MessagesState';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore } from '../store/AppStore';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import {
  HdsListItemCard,
  HdsNavDestination,
  PrefixCustomBuilder
} from '@kit.UIDesignKit';
import { resByName } from '../tools/I18n';

// 对应 iOS DataSettingView：设备信息、消息统计、清理入口，全部使用 HdsListItemCard
@ComponentV2
export struct DataSettingsView {
  @Local state: MessagesState = MessagesState.shared;
  @Local prop: AppStoreModel = appStore.getState();
  private listScroller: ListScroller = new ListScroller();
  // 危险操作回调（@Builder 间传递，点击卡片时调用）
  private pendingOk: () => void = (): void => {};

  build() {
    HdsNavDestination() {
      // HDS 卡片自带外边距，hPadding 设 0 避免双倍缩进
      NavList({ space: 8, hPadding: 0, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
        scroller: this.listScroller }) {
        this.sectionHeader($r('app.string.section_device'))
        ListItem() {
          this.copyCard($r('sys.symbol.person'), '#34C759', 'TOKEN', this.prop.pushToken)
        }
        ListItem() {
          this.copyCard($r('sys.symbol.device_2'), '#5856D6', $r('app.string.device_id'), this.prop.deviceId)
        }
        // 华为账号凭证（登录后展示，与 TOKEN 同样脱敏，点击复制）
        if (this.prop.huaweiUnionID) {
          ListItem() {
            this.copyCard($r('sys.symbol.person_2'), '#FF9500', $r('app.string.huawei_union_id'),
              this.prop.huaweiUnionID)
          }
        }
        if (this.prop.huaweiOpenID) {
          ListItem() {
            this.copyCard($r('sys.symbol.key'), '#AF52DE', $r('app.string.huawei_open_id'),
              this.prop.huaweiOpenID)
          }
        }

        this.sectionHeader($r('app.string.section_messages_mgmt'))
        ListItem() {
          this.totalStatCard()
        }
        ListItem() {
          this.unreadStatCard()
        }
        ListItem() {
          this.dangerCard($r('sys.symbol.checkmark_circle_fill'), '#34C759', $r('app.string.clear_read'),
            this.s('clear_read_message'),
            (): void => { messageStore.deleteAllRead().then(() => this.state.refresh()); })
        }
        ListItem() {
          this.dangerCard($r('sys.symbol.archivebox'), '#FF3B30', $r('app.string.clear_all'),
            this.s('clear_all_message'),
            (): void => { messageStore.clear().then(() => this.state.refresh()); })
        }
      }
    }
    .titleBar(hdsTitleBar($r('app.string.title_data')))
    .bindToScrollable([this.listScroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
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
        .padding({ left: 16, right: 16, top: 14, bottom: 2 })
    }
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

  // 复制行内容：标题 + 脱敏值
  @Builder
  copyContent(label: ResourceStr, raw: string) {
    Row() {
      Text(label)
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(this.maskString(raw))
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 180 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 总消息数行：在被渲染的 customBuilder 内读 @Trace total，删除后数量实时刷新
  @Builder
  totalStatContent() {
    Row() {
      Text($r('app.string.total_messages'))
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(`${this.state.total}`)
        .fontSize(17)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  totalStatCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => {
        this.iconTile($r('sys.symbol.ellipsis_message'), '#007AFF');
      }),
      textItem: { customBuilder: (): void => { this.totalStatContent(); } },
      cardBackgroundColor: $r('app.color.bg_card')
    })
  }

  // 未读消息数行：读 @Trace unread
  @Builder
  unreadStatContent() {
    Row() {
      Text($r('app.string.unread_messages'))
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(`${this.state.unread}`)
        .fontSize(17)
        .fontColor('#FF9500')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  unreadStatCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => {
        this.iconTile($r('sys.symbol.ellipsis_message_fill'), '#FF9500');
      }),
      textItem: { customBuilder: (): void => { this.unreadStatContent(); } },
      cardBackgroundColor: $r('app.color.bg_card')
    })
  }

  // 危险行内容：红色标题 + 箭头
  @Builder
  dangerContent(label: ResourceStr) {
    Row() {
      Text(label)
        .fontSize(17)
        .fontColor('#FF3B30')
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  copyCard(icon: Resource, color: string, label: ResourceStr, raw: string) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile(icon, color); }),
      textItem: { customBuilder: (): void => { this.copyContent(label, raw); } },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => this.copyTap(raw)
    })
  }

  @Builder
  dangerCard(icon: Resource, color: string, label: ResourceStr, message: string, onOk: () => void) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile(icon, color); }),
      textItem: { customBuilder: (): void => { this.dangerContent(label); } },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => {
        this.pendingOk = onOk;
        this.confirm(message);
      }
    })
  }

  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  confirm(message: string): void {
    this.getUIContext().getPromptAction().showDialog({
      title: this.s('confirm_delete_title'),
      message,
      buttons: [
        { text: this.s('action_cancel'), color: $r('app.color.text_secondary') },
        { text: this.s('action_delete'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) this.pendingOk();
    });
  }

  copyTap(content: string): void {
    const pasteData: pasteboard.PasteData =
      pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
    pasteboard.getSystemPasteboard().setData(pasteData);
    this.getUIContext().getPromptAction().showToast({
      message: this.s('copy_success'),
      duration: 2000,
      showMode: promptAction.ToastShowMode.DEFAULT,
      bottom: 80
    });
    Haptics.success();
  }

  maskString(str: string): string {
    if (str.length <= 10) return str;
    return `${str.slice(0, 5)}*****${str.slice(-5)}`;
  }
}
