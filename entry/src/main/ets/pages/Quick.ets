import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Haptics } from '../tools/Haptics';
import { promptAction } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { ServerInfo } from '../model/ServerInfo';
import { uiState } from '../model/UIState';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList } from '../components/NavList';
import { HdsNavigation, HdsListItemCard, PrefixCustomBuilder, HdsSideBar } from '@kit.UIDesignKit';
import { sendQuickPush, buildQuickSendOptions } from '../tools/QuickSender';
import { resByName } from '../tools/I18n';

interface QuickTarget {
  url: string;
  key: string;
}

// 快捷发送页：列表为**非本机**发送目标服务器（与设置页本机接收用的 servers 分开持久化），
// 显示备注与 url/key 合体地址。点击卡片选中目标，底部出现聊天式输入条（输入框+发送按钮），
// 键盘弹起时整条自动顶到键盘上方。确认后
// GET {url}/{key}?title=…&body=<输入内容>&copy=body[&group=…]，其余可选参数见发送选项侧边栏。
@ComponentV2
export struct QuickView {
  @Local prop: AppStoreModel = appStore.getState();
  @Local showSheet: boolean = false;
  @Local inputTarget: string = '';
  @Local inputName: string = '';
  @Local sendText: string = '';
  // 当前选中的发送目标；非空时显示底部输入条
  @Local target: ServerInfo | null = null;
  @Local sending: boolean = false;
  // 发送选项侧边栏是否展示
  @Local showOptions: boolean = false;
  // 侧边栏表单草稿（关闭时一次性保存）
  @Local optTitle: string = '';
  @Local optIcon: string = '';
  @Local optSound: string = '';
  @Local optGroup: string = '';
  // 侧边栏面板高度(vp)：HdsSideBar 抽屉内容按无界高度测量，layoutWeight 的 Scroll 不会产生滚动，
  // 需用窗口实测高度给面板定高（面板始终整屏高、顶部对齐）；键盘弹起时只在滚动内容底部追加避让空间
  @Local panelHeight: number = 0;
  // 键盘高度(vp)，收起为 0；作为 Scroll 内容底部内边距，让末尾元素能滚到键盘上方
  @Local keyboardHeight: number = 0;
  private windowHeight: number = 0;
  // 点发送按钮期间为 true，屏蔽按钮触摸可能触发的 onBlur
  private blurGuard: boolean = false;
  private stack: NavPathStack = new NavPathStack();
  private listScroller: Scroller = new Scroller();

  private s(name: string): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name);
  }

  aboutToAppear(): void {
    this.loadOptionsDraft();
    this.measurePanel();
  }

  aboutToDisappear(): void {
    // 恢复系统默认的窗口上移避让，避免影响其他页面（底部聊天输入条依赖默认行为）
    // KeyboardAvoidMode.OFFSET（const enum 成员 ArkTS 不可直接引用）
    this.getUIContext().setKeyboardAvoidMode(0);
  }

  // 读窗口高度并监听键盘避让区。侧边栏打开期间键盘避让为 NONE：窗口不做任何位移/缩放
  // （Tab 栏等外部布局完全不动），键盘高度作为滚动内容底部内边距在面板内部消化
  private async measurePanel(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      const win = await window.getLastWindow(ctx);
      this.windowHeight = px2vp(win.getWindowProperties().windowRect.height);
      this.updatePanelHeight();
      win.on('windowSizeChange', (size: Size): void => {
        this.windowHeight = px2vp(size.height);
        this.updatePanelHeight();
      });
      // NONE 模式下窗口不调整，但键盘避让区仍会上报，用它给滚动内容追加底部空间
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions): void => {
        if (data.type === window.AvoidAreaType.TYPE_KEYBOARD) {
          this.keyboardHeight = px2vp(data.area.bottomRect.height);
        }
      });
    } catch (e) {
      console.error(`measurePanel failed: ${(e as Error).message}`);
    }
  }

  // 面板始终占满窗口高度；键盘避让只体现在内容底部内边距
  private updatePanelHeight(): void {
    this.panelHeight = Math.max(0, this.windowHeight);
  }

  // 侧边栏显隐切换键盘避让：NONE(=4) 窗口完全不动，推动只发生在面板内部；关闭恢复 OFFSET(=0)
  @Monitor('showOptions')
  onShowOptionsChanged(): void {
    this.getUIContext().setKeyboardAvoidMode(this.showOptions ? 4 : 0);
    if (!this.showOptions) {
      // 关闭即收起键盘（完成/✕/蒙层三条路径都经过这里）
      this.getUIContext().getFocusController().clearFocus();
      this.keyboardHeight = 0;
      this.updatePanelHeight();
    }
  }

  // 从持久化配置载入侧边栏草稿
  private loadOptionsDraft(): void {
    this.optTitle = this.prop.quickTitle;
    this.optIcon = this.prop.quickIcon;
    this.optSound = this.prop.quickSound;
    this.optGroup = this.prop.quickGroup;
  }

  // 打开侧边栏前同步一次配置（防止旧草稿残留）
  private openOptions(): void {
    this.loadOptionsDraft();
    this.showOptions = true;
  }

  // 侧边栏关闭时保存：空串表示不带该参数
  private saveOptions(): void {
    appStore.dispatch(AppActions.setQuickOptions({
      title: this.optTitle.trim(),
      icon: this.optIcon.trim(),
      sound: this.optSound.trim(),
      group: this.optGroup.trim()
    }));
  }

  // MARK: - 选中 / 发送

  private openSend(s: ServerInfo): void {
    if (this.sending) {
      return;
    }
    // 再次点击已选中的卡片则收起输入条
    if (this.target?.id === s.id) {
      this.closeSend();
      return;
    }
    this.target = s;
    this.sendText = '';
    // 隐藏悬浮页签：只动画改高度，宽度不缩
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, (): void => {
      uiState.tabBarVisible = false;
    });
    // 自动获焦唤起键盘，窗口默认避让会把底部输入条顶到键盘上方
    setTimeout((): void => this.getUIContext().getFocusController().requestFocus('quickSendInput'), 150);
  }

  private closeSend(): void {
    if (this.sending) {
      return;
    }
    this.target = null;
    this.sendText = '';
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, (): void => {
      uiState.tabBarVisible = true;
    });
  }

  async doSend(): Promise<void> {
    if (this.sending || !this.target) {
      return;
    }
    const clip: string = this.sendText.trim();
    if (!clip) {
      return;
    }
    const target: ServerInfo = this.target;

    this.sending = true;
    const ok: boolean = await sendQuickPush(target, clip, buildQuickSendOptions(this.s('quick_notify_title')));
    this.sending = false;
    // 发送完毕：收起键盘并隐藏输入条，恢复底部 Tab 栏
    this.getUIContext().getFocusController().clearFocus();
    this.blurGuard = false;
    this.closeSend();
    this.toast(this.s(ok ? 'quick_sent' : 'quick_send_failed'));
  }

  // MARK: - 添加 / 删除

  private openAdd(): void {
    this.inputTarget = '';
    this.inputName = '';
    this.showSheet = true;
  }

  // 解析「域名/KEY」合体输入：补全协议、去尾部斜杠，最后一个路径段作为 KEY
  private parseTarget(raw: string): QuickTarget | null {
    let t: string = raw.trim().replace(/\/+$/, '');
    if (!t) {
      return null;
    }
    if (!/^https?:\/\//i.test(t)) {
      t = `https://${t}`;
    }
    const slash: number = t.lastIndexOf('/');
    if (slash <= 8) {
      return null;
    } // 至少要在协议前缀（https://）之后有内容
    const url: string = t.substring(0, slash);
    const key: string = t.substring(slash + 1);
    if (!url || !key) {
      return null;
    }
    const target: QuickTarget = { url, key };
    return target;
  }

  private async saveTarget(): Promise<void> {
    const parsed: QuickTarget | null = this.parseTarget(this.inputTarget);
    if (!parsed) {
      this.toast(this.s('quick_need_target'));
      return;
    }
    const exists: boolean = this.prop.quickServers.some(
      (x: ServerInfo): boolean => x.url === parsed.url && x.key === parsed.key);
    if (exists) {
      this.toast(this.s('server_exists'));
      return;
    }
    const target = new ServerInfo();
    target.id = util.generateRandomUUID(false);
    target.url = parsed.url;
    target.key = parsed.key;
    target.remark = this.inputName.trim();
    await appStore.dispatch(AppActions.addQuickServer(target));
    this.showSheet = false;
  }

  private confirmDelete(s: ServerInfo): void {
    this.getUIContext().getPromptAction().showDialog({
      title: this.s('delete_server_title'),
      message: `${s.url}/${s.key}`,
      buttons: [
        { text: this.s('action_cancel'), color: $r('app.color.text_secondary') },
        { text: this.s('action_delete'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) {
        appStore.dispatch(AppActions.removeQuickServer(s.id));
        if (this.target?.id === s.id) {
          this.closeSend();
        }
      }
    });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({
      message,
      duration: 2000,
      showMode: promptAction.ToastShowMode.DEFAULT,
      bottom: 80
    });
    Haptics.success();
  }

  // MARK: - 视图

  // 左侧纸飞机方块
  @Builder
  iconTile(s: ServerInfo) {
    Stack() {
      SymbolGlyph($r('sys.symbol.paperplane_fill'))
        .fontSize(18)
        .fontColor([Color.White])
    }
    .width(30)
    .height(30)
    .borderRadius(8)
    .backgroundColor(this.target?.id === s.id ? '#7AB8D4' : '#1698CE')
  }

  // B 区：备注名 + url/key 合体地址；默认服务器右侧显示对勾
  @Builder
  cardText(s: ServerInfo) {
    Row() {
      Column() {
        Text(s.remark || `${s.url}/${s.key}`)
          .fontSize(16)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (s.remark) {
          Text(`${s.url}/${s.key}`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (s.isDefault) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(20)
          .fontColor(['#1698CE'])
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  serverCard(s: ServerInfo) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => {
        this.iconTile(s);
      }),
      textItem: {
        customBuilder: (): void => {
          this.cardText(s);
        }
      },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => {
        this.openSend(s);
      }
    })
  }

  @Builder
  deleteButton(action: () => void) {
    Button($r('app.string.action_delete'))
      .backgroundColor(Color.Red)
      .fontColor(Color.White)
      .padding({
        left: 20,
        right: 20,
        top: 8,
        bottom: 8
      })
      .margin({ left: 10 })
      .onClick(action)
  }

  // 右滑（start）：设为默认发送目标
  @Builder
  setDefaultButton(s: ServerInfo) {
    Button(s.isDefault ? $r('app.string.default_tag') : $r('app.string.set_default'))
      .backgroundColor(s.isDefault ? $r('app.color.text_tertiary') : '#1698CE')
      .fontColor(Color.White)
      .padding({
        left: 20,
        right: 20,
        top: 8,
        bottom: 8
      })
      .margin({ right: 10 })
      .onClick((): void => {
        appStore.dispatch(AppActions.setQuickDefault(s.id));
        this.toast(this.s('default_set'));
      })
  }

  @Builder
  emptyTip() {
    Column() {
      Blank()
      Text($r('app.string.quick_empty'))
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
      Blank()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  addSheet() {
    Column({ space: 14 }) {
      Text($r('app.string.add_server'))
        .fontSize(18)
        .fontWeight(700)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 4 })
      TextInput({ placeholder: $r('app.string.quick_target_placeholder'), text: $$this.inputTarget })
        .key('quickTargetInput')
        .height(48)
        .backgroundColor($r('app.color.bg_chip'))
        .borderRadius(10)
        .padding({ left: 14, right: 14 })
        .enterKeyType(EnterKeyType.Next)
        .onSubmit((): void => this.getUIContext().getFocusController().requestFocus('quickNameInput'))
      TextInput({ placeholder: $r('app.string.quick_name_placeholder'), text: $$this.inputName })
        .key('quickNameInput')
        .height(48)
        .backgroundColor($r('app.color.bg_chip'))
        .borderRadius(10)
        .padding({ left: 14, right: 14 })
        .enterKeyType(EnterKeyType.Done)
        .onSubmit((): void => {
          this.saveTarget();
        })
      Button($r('app.string.action_save'))
        .width('100%')
        .height(48)
        .borderRadius(10)
        .backgroundColor('#1698CE')
        .fontColor(Color.White)
        .fontSize(16)
        .margin({ top: 4 })
        .onClick((): void => {
          this.saveTarget();
        })
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 36,
      bottom: 36
    })
    .backgroundColor($r('app.color.bg_card'))
  }

  // 聊天式底部输入条：折叠按钮 + 输入框（含发送按钮）；键盘弹起时整条被顶到键盘上方
  @Builder
  inputBar() {
    Row({ space: 8 }) {
      // 收起输入条、恢复 Tab 栏
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(16)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor($r('app.color.bg_chip'))
      .onClick((): void => {
        this.closeSend();
      })

      Row({ space: 6 }) {
        TextInput({
          placeholder: this.target?.remark || (this.target ? `${this.target.url}/${this.target.key}` : ''),
          text: $$this.sendText
        })
          .key('quickSendInput')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(Color.Transparent)
          .padding({ left: 4, right: 4 })
          .enterKeyType(EnterKeyType.Send)
          .onSubmit((): void => {
            this.doSend();
          })
          // 键盘以任何方式收起（系统返回等）即隐藏输入条；发送中/点发送按钮时不动
          .onBlur((): void => {
            if (!this.sending && !this.blurGuard) {
              this.closeSend();
            }
          })

        Button() {
          if (this.sending) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White)
          } else {
            SymbolGlyph($r('sys.symbol.arrow_up_circle_fill'))
              .fontSize(28)
              .fontColor([this.sendText.trim().length > 0 ? '#1698CE' : $r('app.color.text_tertiary')])
          }
        }
        .width(36)
        .height(36)
        .padding(0)
        .backgroundColor(Color.Transparent)
        .enabled(this.sendText.trim().length > 0 && !this.sending)
        // 按下瞬间置守卫：若点按钮导致输入框失焦，不要被 onBlur 当成手动收起而提前关闭
        .onTouch((event: TouchEvent): void => {
          if (event.type === TouchType.Down) {
            this.blurGuard = true;
          }
        })
        .onClick((): void => {
          this.doSend();
        })
      }
      .layoutWeight(1)
      .height(44)
      .borderRadius(22)
      .backgroundColor($r('app.color.bg_chip'))
      .padding({ left: 10, right: 6 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: uiState.navIndicatorHeight > 0 ? uiState.navIndicatorHeight : 8
    })

    // .backgroundColor($r('app.color.bg_card'))
  }

  // 侧边栏单个输入卡片：标题 + 输入框
  @Builder
  optionField(label: ResourceStr, placeholder: ResourceStr, value: string,
    onChange: (v: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      TextInput({ placeholder, text: value })
        .height(44)
        .backgroundColor($r('app.color.bg_chip'))
        .borderRadius(10)
        .padding({ left: 14, right: 14 })
        .onChange(onChange)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
  }

  // 发送选项侧边栏：标题/图标/提示音/分组，留空的项发送时不带
  @Builder
  optionPanel() {
    Column() {
      Row() {
        Text($r('app.string.quick_options'))
          .fontSize(20)
          .fontWeight(700)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Button() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(15)
            .fontColor([$r('app.color.text_secondary')])
        }
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor($r('app.color.bg_chip'))
        .onClick((): void => {
          this.showOptions = false;
        })
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: uiState.statusBarHeight + 10, bottom: 8 })

      Scroll() {
        Column({ space: 10 }) {
          this.optionField($r('app.string.quick_option_title'),
            $r('app.string.quick_option_title_ph'), this.optTitle, (v: string): void => {
              this.optTitle = v;
            })
          this.optionField($r('app.string.quick_option_icon'),
            $r('app.string.quick_option_icon_ph'), this.optIcon, (v: string): void => {
              this.optIcon = v;
            })
          this.optionField($r('app.string.quick_option_sound'),
            $r('app.string.quick_option_sound_ph'), this.optSound, (v: string): void => {
              this.optSound = v;
            })
          this.optionField($r('app.string.quick_option_group'),
            $r('app.string.quick_option_group_ph'), this.optGroup, (v: string): void => {
              this.optGroup = v;
            })

          Button($r('app.string.action_done'))
            .width('100%')
            .height(48)
            .borderRadius(12)
            .backgroundColor('#1698CE')
            .fontColor(Color.White)
            .fontSize(16)
            .margin({ top: 6 })
            .onClick((): void => {
              this.showOptions = false;
            })
        }
        .width('100%')
        // 键盘弹起：底部追加键盘高度的空白，末尾元素可滚到键盘上方；收起时只让出手势条
        .padding({
          left: 12,
          right: 12,
          bottom: this.keyboardHeight > 0
            ? this.keyboardHeight + 16
            : (uiState.navIndicatorHeight > 0 ? uiState.navIndicatorHeight : 8) + 16
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .width('100%')
    .height(this.panelHeight > 0 ? this.panelHeight : '100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }

  // HdsSideBar 内容区：服务器列表 + 底部输入条
  @Builder
  quickContent() {
    Column() {
      HdsNavigation(this.stack) {
        if (this.prop.quickServers.length === 0) {
          this.emptyTip()
        } else {
          // HDS 卡片自带 16vp 外边距，hPadding 设 0
          NavList({ space: 8, hPadding: 0, scroller: this.listScroller }) {
            ForEach(this.prop.quickServers, (s: ServerInfo) => {
              ListItem() {
                this.serverCard(s)
              }
              .swipeAction({
                start: this.setDefaultButton(s),
                end: this.deleteButton((): void => this.confirmDelete(s))
              })
            }, (s: ServerInfo) => s.id)
          }
        }
      }
      .layoutWeight(1)
      .mode(NavigationMode.Auto)
      .bindToScrollable([this.listScroller])
      .titleBar(hdsTitleBar($r('app.string.title_quick'), [
        {
          content: {
            icon: $r('sys.symbol.slider_horizontal_2_1'),
            action: (): void => {
              this.openOptions();
            }
          }
        },
        {
          content: {
            icon: $r('sys.symbol.plus'),
            action: (): void => {
              this.openAdd();
              Haptics.success();
            }
          }
        }
      ]))
      .bindSheet($$this.showSheet, this.addSheet(), {
        height: SheetSize.FIT_CONTENT,
        dragBar: true,
        backgroundColor: $r('app.color.bg_card')
      })
      .backgroundColor($r('app.color.bg_page'))

      if (this.target !== null) {
        this.inputBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  build() {
    HdsSideBar({
      sideBarContainerType: SideBarContainerType.Overlay,
      isShowSideBar: this.showOptions,
      $isShowSideBar: (isShow: boolean): void => {
        this.showOptions = isShow;
      },
      onChange: (isShow: boolean): void => {
        this.showOptions = isShow;
        // 点蒙层/手势关闭同样落盘
        if (!isShow) {
          this.saveOptions();
        }
      },
      sideBarWidth: 320,
      minSideBarWidth: 280,
      maxSideBarWidth: 360,
      sideBarColor: $r('app.color.bg_page'),
      contentColor: $r('app.color.bg_page'),
      sideBarPanelBuilder: (): void => {
        this.optionPanel();
      },
      contentPanelBuilder: (): void => {
        this.quickContent();
      }
    })
      .width('100%')
      .height('100%')
  }
}
