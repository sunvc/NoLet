import { common, Want, abilityAccessCtrl } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { HdsNavDestination, HdsListItemCard, PrefixCustomBuilder } from '@kit.UIDesignKit';
import { resByName } from '../tools/I18n';
import { generateLanCode } from '../tools/LanShare';

// 更多设置：快捷发送开关（自动发送 / 弹窗确认）与系统设置入口
@ComponentV2
export struct MoreSettingsView {
  @Local prop: AppStoreModel = appStore.getState();
  private listScroller: Scroller = new Scroller();

  private s(name: string): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name);
  }

  // 左侧彩色圆角方块图标
  @Builder
  iconTile(icon: Resource, color: ResourceColor) {
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

  // 自动发送开关行 B 区
  @Builder
  autoSendText() {
    Row() {
      Column() {
        Text($r('app.string.auto_send'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text($r('app.string.auto_send_desc'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.prop.autoSend })
        .selectedColor('#1698CE')
        .margin({ left: 10 })
        .onChange((on: boolean): void => { this.toggleWithPermission(on, true); })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 快捷发送开关行 B 区
  @Builder
  quickSendText() {
    Row() {
      Column() {
        Text($r('app.string.quick_send_toggle'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text($r('app.string.quick_send_desc'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.prop.quickSend })
        .selectedColor('#1698CE')
        .margin({ left: 10 })
        .onChange((on: boolean): void => { this.toggleWithPermission(on, false); })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 自动发送
  @Builder
  autoSendCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile($r('sys.symbol.bolt_fill'), '#FF9500'); }),
      textItem: { customBuilder: (): void => { this.autoSendText(); } },
      cardBackgroundColor: $r('app.color.bg_card'),
    })
  }

  // 快捷发送（弹窗确认）
  @Builder
  quickSendCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile($r('sys.symbol.paperplane_fill'), '#1698CE'); }),
      textItem: { customBuilder: (): void => { this.quickSendText(); } },
      cardBackgroundColor: $r('app.color.bg_card'),
    })
  }

  // 开启前申请剪贴板读取权限；关闭直接生效，拒绝授权则保持关闭
  private async toggleWithPermission(on: boolean, isAuto: boolean): Promise<void> {
    if (!on) {
      appStore.dispatch(isAuto ? AppActions.setAutoSend(false) : AppActions.setQuickSend(false));
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      const aac = abilityAccessCtrl.createAtManager();
      const result = await aac.requestPermissionsFromUser(ctx, ['ohos.permission.READ_PASTEBOARD']);
      if (result.authResults.length > 0 && result.authResults[0] === 0) {
        appStore.dispatch(isAuto ? AppActions.setAutoSend(true) : AppActions.setQuickSend(true));
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: resByName(ctx, 'clipboard_permission_denied'),
          duration: 2000,
          bottom: 120
        });
      }
    } catch (e) {
      console.error(`request READ_PASTEBOARD failed: ${(e as BusinessError).message}`);
    }
  }

  // 震动开关行 B 区
  @Builder
  hapticsText() {
    Row() {
      Column() {
        Text($r('app.string.vibration'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text($r('app.string.vibration_desc'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.prop.haptics })
        .selectedColor('#1698CE')
        .margin({ left: 10 })
        .onChange((on: boolean): void => {
          appStore.dispatch(AppActions.setHaptics(on));
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 震动反馈开关
  @Builder
  hapticsCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile($r('sys.symbol.waveform'), '#AF52DE'); }),
      textItem: { customBuilder: (): void => { this.hapticsText(); } },
      cardBackgroundColor: $r('app.color.bg_card'),
    })
  }

  // 局域网共享开关行 B 区
  @Builder
  lanShareText() {
    Row() {
      Column() {
        Text($r('app.string.lan_share'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text($r('app.string.lan_share_desc'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.prop.lanShare })
        .selectedColor('#1698CE')
        .margin({ left: 10 })
        .onChange((on: boolean): void => { this.toggleLanShare(on); })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 局域网共享开关
  @Builder
  lanShareCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile($r('sys.symbol.wifi'), '#34C759'); }),
      textItem: { customBuilder: (): void => { this.lanShareText(); } },
      cardBackgroundColor: $r('app.color.bg_card'),
    })
  }

  // 接收码行 B 区：右侧显示 6 位码
  @Builder
  lanCodeText() {
    Row() {
      Text($r('app.string.lan_code'))
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
      Blank()
      Text(this.prop.lanCode)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(2)
        .margin({ right: 6 })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 接收码行：点击弹菜单（复制 / 重新生成）
  @Builder
  lanCodeCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.iconTile($r('sys.symbol.key'), '#8E8E93'); }),
      textItem: { customBuilder: (): void => { this.lanCodeText(); } },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => this.showLanCodeMenu()
    })
  }

  // 开启前申请剪贴板读取权限；首次开启自动生成接收码；拒绝授权则保持关闭
  private async toggleLanShare(on: boolean): Promise<void> {
    if (!on) {
      appStore.dispatch(AppActions.setLanShare(false));
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      const aac = abilityAccessCtrl.createAtManager();
      const result = await aac.requestPermissionsFromUser(ctx, ['ohos.permission.READ_PASTEBOARD']);
      if (result.authResults.length > 0 && result.authResults[0] === 0) {
        if (!appStore.getState().lanCode) {
          appStore.dispatch(AppActions.setLanCode(generateLanCode()));
        }
        appStore.dispatch(AppActions.setLanShare(true));
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: resByName(ctx, 'clipboard_permission_denied'),
          duration: 2000,
          bottom: 120
        });
      }
    } catch (e) {
      console.error(`request READ_PASTEBOARD failed: ${(e as BusinessError).message}`);
    }
  }

  // 接收码操作菜单：复制或重新生成
  private showLanCodeMenu(): void {
    this.getUIContext().getPromptAction().showActionMenu({
      title: this.s('lan_code'),
      buttons: [
        { text: this.s('lan_code_copy'), color: '#1698CE' },
        { text: this.s('lan_code_regenerate'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ActionMenuSuccessResponse): void => {
      if (result.index === 0) {
        const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, appStore.getState().lanCode);
        pasteboard.getSystemPasteboard().setData(data);
        this.getUIContext().getPromptAction().showToast({
          message: this.s('lan_code_copied'),
          duration: 2000,
          bottom: 120
        });
      } else if (result.index === 1) {
        appStore.dispatch(AppActions.setLanCode(generateLanCode()));
        this.getUIContext().getPromptAction().showToast({
          message: this.s('lan_code_regenerated'),
          duration: 2000,
          bottom: 120
        });
      }
    }).catch((): void => {});
  }

  // 系统设置行 B 区
  @Builder
  systemSettingsText() {
    Row() {
      Text($r('app.string.menu_system_settings'))
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 系统设置行
  @Builder
  systemSettingsCard() {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => {
        this.iconTile($r('sys.symbol.slider_horizontal_2_1'), '#34C759');
      }),
      textItem: { customBuilder: (): void => { this.systemSettingsText(); } },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => this.openSystemSettings()
    })
  }

  // 拉起系统设置中本应用的详情页（通知开关、权限等）
  private openSystemSettings(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // ArkTS 禁止 Record 直接对象字面量，经 JSON.parse 转换
    let parameters: Record<string, Object> = {};
    try {
      parameters = JSON.parse(`{"pushParams":"${ctx.abilityInfo.bundleName}"}`) as Record<string, Object>;
    } catch (e) {
      console.error(`system settings params failed: ${(e as Error).message}`);
    }
    const want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters
    };
    ctx.startAbility(want).catch((err: BusinessError): void => {
      console.error(`open system settings failed: ${err.code} ${err.message}`);
    });
  }

  build() {
    HdsNavDestination() {
      NavList({ space: 8, hPadding: 0, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
        scroller: this.listScroller }) {
        this.sectionHeader($r('app.string.section_quick_settings'))
        ListItem() {
          this.autoSendCard()
        }
        ListItem() {
          this.quickSendCard()
        }

        this.sectionHeader($r('app.string.section_general'))
        ListItem() {
          this.hapticsCard()
        }
        ListItem() {
          this.systemSettingsCard()
        }

        this.sectionHeader($r('app.string.section_lan'))
        ListItem() {
          this.lanShareCard()
        }
        if (this.prop.lanShare) {
          ListItem() {
            this.lanCodeCard()
          }
        }
      }
    }
    .titleBar(hdsTitleBar($r('app.string.menu_more')))
    .bindToScrollable([this.listScroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
