import { bundleManager, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { hdsTitleBar } from '../components/HdsTitle';
import { HdsNavDestination, HdsListItemCard } from '@kit.UIDesignKit';
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { uiState } from '../model/UIState';

// 关于页：参照 Notes1 AboutUs —— 图标名称、HDS 卡片行、贴底版权信息
@ComponentV2
export struct AboutView {
  @Local version: string = '';
  @Local prop: AppStoreModel = appStore.getState();
  private listScroller: Scroller = new Scroller();

  // 华为登录按钮控制器与样式参数
  private hwController: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController();
  private hwParams: loginComponentManager.LoginWithHuaweiIDButtonParams = {
    loginType: loginComponentManager.LoginType.ID,
    style: loginComponentManager.Style.BUTTON_RED
  };

  aboutToAppear(): void {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      .then(info => {
        this.version = info.versionName;
      })
      .catch((e: BusinessError) => console.error(e.message));
    // 注册华为账号登录结果回调：成功读取 unionID/openID/authorizationCode/idToken
    this.hwController.onClickLoginWithHuaweiIDButton(
      (error: BusinessError, data: loginComponentManager.HuaweiIDCredential): void => {
        // 用户在授权弹窗中取消：属正常操作，不报错、不改状态，按钮仍可再次点击
        if (error) {
          if (error.code === 1001502012) {
            console.info('HUAWEI ID authorization canceled by user');
            return;
          }
          console.error(`HUAWEI ID login failed: ${error.code} ${error.message}`);
          return;
        }
        console.info(`HUAWEI ID login ok: unionID=${data.unionID} openID=${data.openID} ` +
          `code=${data.authorizationCode} idToken=${data.idToken ?? ''}`);
        // 本地保存凭证，页面数据管理页可见
        appStore.dispatch(AppActions.setHuaweiCredential(data.unionID, data.openID));
      });
  }

  /// 退出华为账号：确认后清除本地凭证，页面回到登录按钮
  showHuaweiLogout(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.huawei_logout'),
      message: $r('app.string.huawei_logout_message'),
      buttons: [
        { text: $r('app.string.action_cancel'), color: '#8E8E93' },
        { text: $r('app.string.huawei_logout'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) {
        appStore.dispatch(AppActions.clearHuaweiCredential());
      }
    }).catch((): void => {});
  }

  openLink(url: string): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    context.startAbility({ action: 'ohos.want.action.viewData', uri: url })
      .catch((e: BusinessError) => console.error(e.message));
  }

  // 应用图标 + 名称
  @Builder
  appIconAndName() {
    Column() {
      // layered_image.json 无法直接被 Image 渲染，手动叠加背景层与前景层还原应用图标
      Stack() {
        Image($r('app.media.background'))
          .width('100%')
          .height('100%')
        Image($r('app.media.foreground'))
          .width('100%')
          .height('100%')
      }
      .width(72)
      .height(72)
      .borderRadius(16)
      .clip(true)

      Text('NoLet')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 10, bottom: 30 })
    }
    .width('100%')
  }

  // B 区内容：标题左对齐，值/地址右对齐（可点行带右侧箭头）
  @Builder
  cardText(label: ResourceStr, value: ResourceStr, withArrow: boolean) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Text(value)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 12 })
      if (withArrow) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('app.color.text_tertiary')])
          .margin({ left: 6 })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // 版本信息行（不可点，版本号在右）
  @Builder
  versionCard() {
    HdsListItemCard({
      textItem: {
        customBuilder: (): void => {
          this.cardText($r('app.string.version_info'), this.version, false);
        }
      },
      cardBackgroundColor: $r('app.color.bg_card')
    })
  }

  // 链接行：地址在右，点击外链跳转
  @Builder
  linkCard(label: ResourceStr, value: string, url: string) {
    HdsListItemCard({
      textItem: {
        customBuilder: (): void => {
          this.cardText(label, value, true);
        }
      },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => this.openLink(url)
    })
  }

  build() {
    HdsNavDestination() {
      Column() {
        Scroll(this.listScroller) {
          Column() {
            this.appIconAndName()

            // 版本信息 + 官方网站（HDS 卡片自带 16vp 外边距，外层不再加左右 padding）
            Column({ space: 8 }) {
              this.versionCard()
              this.linkCard($r('app.string.official_site'), 'wzs.app', 'https://wzs.app')
            }
            .width('100%')

            // 源码
            Column({ space: 8 }) {
              this.linkCard($r('app.string.app_source'), 'github.com/sunvc/NoLet',
                'https://github.com/sunvc/NoLet')
              this.linkCard($r('app.string.server_source'), 'github.com/sunvc/NoLets',
                'https://github.com/sunvc/NoLets')
            }
            .width('100%')
            .margin({ top: 16 })

            // 华为账号：未登录显示官方登录按钮，已关联显示可点状态行（点行退出登录）
            if (this.prop.huaweiUnionID.length > 0) {
              Column({ space: 8 }) {
                HdsListItemCard({
                  textItem: {
                    customBuilder: (): void => {
                      this.cardText($r('app.string.huawei_account'),
                        $r('app.string.huawei_linked'), true);
                    }
                  },
                  cardBackgroundColor: $r('app.color.bg_card'),
                  onClick: (): void => this.showHuaweiLogout()
                })
              }
              .width('100%')
              .margin({ top: 16 })
            } else {
              Column() {
                LoginWithHuaweiIDButton({
                  controller: this.hwController,
                  params: this.hwParams
                })
                  .width('100%')
                  .height(40)
              }
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ top: 24 })
            }

            Blank()
              .layoutWeight(1)

            // 底部版权
            Column({ space: 4 }) {
              Text($r('app.string.copyright'))
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.official_site_line'))
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
            .margin({ top: 30, bottom: 30 })
          }
          .width('100%')
          .height('100%')
          .padding({
            left: 0, right: 0,
            top: uiState.statusBarHeight + 56 + 12,
            bottom: uiState.navIndicatorHeight + 20
          })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .titleBar(hdsTitleBar($r('app.string.title_about')))
    .bindToScrollable([this.listScroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
