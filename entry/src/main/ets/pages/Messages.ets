import { Message } from '../model/Message';
import { messageStore, GroupHead } from '../model/DBTools';
import { MessagesState } from '../model/MessagesState';
import { BasicDataSource } from '../model/DataSource';
import { MessageCard } from '../components/MessageCard';
import { MessageDetailView } from './MessageDetail';
import { promptAction, SymbolGlyphModifier, AnimatorResult } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { uiState } from '../model/UIState';
import { messageLocator, MessageLocator, PendingLocate } from '../model/MessageLocator';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList } from '../components/NavList';
import { HdsNavigation, HideMode } from '@kit.UIDesignKit';
import { resByName, displayGroup as localizeGroup } from '../tools/I18n';
import { Haptics } from '../tools/Haptics';
import { MessageReader } from '../components/MessageReader';

const LDOMAIN: number = 0x0000;
const LTAG: string = 'Locate';

@ComponentV2
export struct MessagesView {
  @Local state: MessagesState = MessagesState.shared;
  @Local prop: AppStoreModel = appStore.getState();
  // 定位器单例作为组件成员，@Monitor 才能监听到它的属性（导入常量不在 this 上，无法被监听）
  @Local locator: MessageLocator = messageLocator;
  @Local stack: NavPathStack = new NavPathStack();
  @Local keyword: string = '';
  @Local results: Message[] = [];
  readonly resultSource: BasicDataSource<Message> = new BasicDataSource<Message>();
  @Local searching: boolean = false;
  // 双击卡片全屏查看：当前消息与遮罩显隐
  @Local detailMsg: Message | null = null;
  @Local showDetail: boolean = false;
  // 分组未读竖条呼吸透明度（0.35 ↔ 1 循环，所有未读组同步）
  @Local groupBreath: number = 1;
  // 呼吸动画器（挂载后播放）
  private breathAnimator: AnimatorResult | null = null;

  private searchController: SearchController = new SearchController();
  // bindToScrollable 绑定用：修复弹簧回弹时 FREE 大标题卡在 mini 高度
  private listScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.bindTabBarHide();
    this.enterList();
    // 冷启动点通知：定位命令在本组件挂载前已发布，数据加载后补消费
    this.drainInitialLocate();
    // 延迟到组件挂载后再启动，aboutToAppear 里直接启动动画会被丢弃
    setTimeout((): void => this.startBreath(), 50);
  }

  // 冷启动补消费：等列表数据就绪后取待处理定位命令
  async drainInitialLocate(): Promise<void> {
    await this.state.ensureLoaded();
    const pending: PendingLocate | null = messageLocator.consumePending();
    hilog.info(LDOMAIN, LTAG, `drainInitial pending=${pending ? pending.id : 'null'}`);
    if (pending) await this.runLocate(pending.id, pending.url);
  }

  // 温启动：定位 tick 变化时消费命令
  @Monitor('locator.locateTick')
  onLocateTick(): void {
    const pending: PendingLocate | null = this.locator.consumePending();
    hilog.info(LDOMAIN, LTAG, `onLocateTick pending=${pending ? pending.id : 'null'}`);
    if (pending) this.runLocate(pending.id, pending.url);
  }

  // 按 id 定位消息：分组模式进组详情，平铺模式就地滚动；高亮 5 秒后清除，再跳 url
  async runLocate(id: string, fallbackUrl: string): Promise<void> {
    await this.state.ensureLoaded();
    const msg = await messageStore.getById(id);
    const url: string = msg?.url || fallbackUrl;
    if (!msg) {
      hilog.warn(LDOMAIN, LTAG, `runLocate id=${id} NOT FOUND in db`);
      this.openUrlIfNeeded(url);
      return;
    }

    messageLocator.startHighlight(id);
    if (this.prop.showGroup) {
      hilog.info(LDOMAIN, LTAG, `runLocate id=${id} group mode -> push detail ${msg.group}`);
      this.stack.pushPath({ name: 'detail', param: msg.group });
      // 滚动到目标直接跳 url，不等 5 秒（详情页在后台自行加载定位）
      this.openUrlIfNeeded(url);
    } else {
      const i: number = this.state.flat.findIndex((m: Message): boolean => m.id === id);
      hilog.info(LDOMAIN, LTAG,
        `runLocate id=${id} flat mode flatLen=${this.state.flat.length} arrayIndex=${i}`);
      if (i >= 0) {
        setTimeout((): void => {
          hilog.info(LDOMAIN, LTAG, `scrollToIndex listIndex=${i + 1}`);
          this.listScroller.scrollToIndex(i + 1, true, ScrollAlign.CENTER);
          // 滚动触发后立即跳 url
          this.openUrlIfNeeded(url);
        }, 150);
      } else {
        this.openUrlIfNeeded(url);
      }
    }

    // 边框 5 秒后自动清除（仅清除高亮，与跳转时机无关）
    setTimeout((): void => {
      messageLocator.clearHighlight();
    }, 5000);
  }

  // 打开外部链接（系统浏览器处理）；url 为空不处理
  openUrlIfNeeded(url: string): void {
    if (!url) return;
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.startAbility({ action: 'ohos.want.action.viewData', uri: url })
        .catch((e: Error): void => console.error(`open url failed: ${e.message}`));
    } catch (e) {
      console.error(`open url failed: ${(e as Error).message}`);
    }
  }

  aboutToDisappear(): void {
    this.breathAnimator?.cancel();
    this.breathAnimator = null;
  }

  // 未读分组绿条呼吸：1.1s 0.35 ↔ 1 永久交替（createAnimator 逐帧写透明度）
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
      this.groupBreath = value;
    };
    animator.play();
    this.breathAnimator = animator;
  }

  // 二级页入栈/出栈时联动隐藏与恢复悬浮页签栏（只动画改高度，宽度不缩）
  private bindTabBarHide(): void {
    this.stack.setInterception({
      willShow: (_from: NavDestinationContext | 'navBar', to: NavDestinationContext | 'navBar'): void => {
        this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, (): void => {
          uiState.tabBarVisible = to === 'navBar';
        });
      }
    });
  }

  // 进入消息页：只加载/刷新列表，不主动置已读——冷启动或点通知进入时
  // 仍能看到未读标记；列表模式的已读统一在 App 进后台时清理
  async enterList(): Promise<void> {
    await this.state.ensureLoaded();
    await this.state.reload();
  }

  beginSearch(): void {
    this.getUIContext().animateTo({ duration: 260, curve: Curve.EaseOut }, (): void => {
      this.searching = true;
    });
  }

  exitSearch(): void {
    this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseIn }, (): void => {
      this.searching = false;
    });
    this.keyword = '';
    this.results = [];
    this.resultSource.replaceAll([]);
    this.searchController.stopEditing();
  }

  async runSearch(): Promise<void> {
    const word = this.keyword.trim();
    if (!word) {
      this.results = [];
      this.resultSource.replaceAll([]);
      return;
    }
    this.results = await messageStore.search(word);
    this.resultSource.replaceAll(this.results);
  }

  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  // 规范分组 '默认' 按当前语言显示，其他分组名原样
  private groupName(group: string): string {
    return localizeGroup(this.getUIContext().getHostContext() as common.Context, group);
  }

  // 删除指定日期之前的全部消息：先选日期，再二次确认
  deleteByDate(): void {
    DatePickerDialog.show({
      onAccept: (value: DatePickerResult): void => {
        const year: number = value.year ?? new Date().getFullYear();
        const month: number = value.month ?? 0;
        const day: number = value.day ?? 1;
        const date: Date = new Date(year, month, day);
        const label: string = this.s('date_label', year, month + 1, day);
        this.confirm(this.s('delete_history_title'), this.s('delete_history_message', label), (): void => {
          messageStore.deleteBefore(Math.floor(date.getTime() / 1000)).then((): void => {
            this.state.refresh();
          });
        });
      }
    });
  }

  async deleteOne(id: string): Promise<void> {
    await messageStore.delete(id);
    await this.state.refresh();
  }

  async deleteGroup(group: string): Promise<void> {
    await messageStore.deleteGroup(group);
    await this.state.refresh();
  }

  // 分组行右滑「设为已读」：仅清该组未读，刷新分组蓝点与总角标
  async markGroupRead(group: string): Promise<void> {
    await messageStore.markAllRead(group);
    await this.state.refresh();
  }

  build() {
    Stack() {
      HdsNavigation(this.stack) {

        if (this.searching) {
          this.searchList()
        } else if (this.prop.showGroup) {
          this.groupList()
        } else {
          this.flatList()
        }
      }
      .mode(NavigationMode.Auto)
      .bindToScrollable([this.listScroller])
      .titleBar(hdsTitleBar($r('app.string.title_messages'), [
        {
          content: {
            icon: this.prop.showGroup ? $r('sys.symbol.list_checkmask') : $r('sys.symbol.more'),
            action: () => {
              // 仅切换显示模式，不清理未读
              appStore.dispatch(AppActions.toggleShowGroup());
              Haptics.success();
            }
          }
        },

        {
          content: {
            icon: $r('sys.symbol.magnifyingglass'),
            action: () => {
              this.beginSearch();
              Haptics.success()
            }
          }
        },
        {
          content: {
            icon: $r('sys.symbol.trash'),
            action: () => {
              this.deleteByDate();
              Haptics.success()
            }
          }
        }
      ]))
      .navDestination(this.pageMap)
      .backgroundColor($r('app.color.bg_page'))
      .dynamicHideTitleBar({
        hideTitleArea: false,
        hideStatusBar: true,
        mode: HideMode.SCROLL_UP_TO_BLEND_SCROLL_UP
      })
      .hideTitleBar(this.searching, true)

      if (this.searching) {
        this.searchBar()
      }
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.TopStart)
    // 双击卡片整屏阅读完整内容（$$ 支持系统返回手势关闭）
    .bindContentCover($$this.showDetail, this.detailCover)
  }

  // 搜索态：标题栏隐藏，搜索框置顶到状态栏下方，磨砂光感 + 自搜索按钮位置展开
  @Builder
  searchBar() {
    Row() {
      Search({ value: this.keyword, placeholder: $r('app.string.search_placeholder'),
        controller: this.searchController })
        .layoutWeight(1)
        .height(48)
        .backgroundColor(Color.Transparent)
        .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
        .defaultFocus(true)
        .onChange((value: string): void => {
          this.keyword = value;
          this.runSearch();
        })
        .onSubmit((): void => { this.runSearch(); })
      Text($r('app.string.action_cancel'))
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 12 })
        .onClick((): void => this.exitSearch())
    }
    .width('100%')
    .padding({ left: 10, right: 16 })
    .margin({ top: uiState.statusBarHeight + 8 })
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.6, y: 0.6, centerX: '100%', centerY: 0 }))
        .animation({ duration: 260, curve: Curve.EaseOut })
    )
  }

  private confirm(title: string, message: string, onOk: () => void): void {
    this.getUIContext().getPromptAction().showDialog({
      title,
      message,
      buttons: [
        { text: this.s('action_cancel'), color: $r('app.color.text_secondary') },
        { text: this.s('action_delete'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        onOk();
      }
    });
  }

  @Builder
  pageMap(name: string, param?: object) {
    if (name === 'detail') {
      MessageDetailView({
        group: String(param ?? ''),
        onChanged: (): Promise<void> => this.state.refresh()
      })
    }
  }

  @Builder
  emptyTip(text: string) {
    Column() {
      Blank()
      Text(text)
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
      Blank()
    }
    .width('100%')
    .height('100%')
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

  @Builder
  markReadButton(item: GroupHead) {
    Button(item.unread > 0 ? this.s('action_mark_read') : this.s('action_read_state'))
      .backgroundColor(item.unread > 0 ? '#1698CE' : '#8E8E93')
      .fontColor(Color.White)
      .padding({
        left: 20,
        right: 20,
        top: 8,
        bottom: 8
      })
      .margin({ right: 10 })
      .enabled(item.unread > 0)
      .onClick((): void => {
        if (item.unread > 0) {
          this.markGroupRead(item.head.group);
        }
      })
  }

  @Builder
  flatList() {
    if (this.state.flat.length === 0) {
      this.emptyTip(this.s('empty_messages'))
    } else {
      NavList({ space: 10, hPadding: 10, scrollBarState: BarState.Auto,
        scroller: this.listScroller }) {
        LazyForEach(this.state.flatSource, (item: Message) => {
          ListItem() {
            MessageCard({
              message: item,
              onViewMore: (): void => this.openDetailCover(item)
            })
          }
          .swipeAction({ end: this.deleteButton(() => this.deleteOne(item.id)) })
        }, (item: Message) => item.id)
      }
    }
  }

  @Builder
  searchList() {
    if (this.results.length === 0) {
      this.emptyTip(this.keyword.trim() ? this.s('no_results') : this.s('search_hint'))
    } else {
      // 标题栏已隐藏：顶部避让 = 搜索框 48vp + 上下间隔（窗口已由系统让出状态栏区域）
      NavList({ space: 10, hPadding: 10, scrollBarState: BarState.Auto,
        titleHeight: 0, topGap: 64, scroller: this.listScroller }) {
        LazyForEach(this.resultSource, (item: Message) => {
          ListItem() {
            MessageCard({
              message: item,
              onViewMore: (): void => this.openDetailCover(item)
            })
              .onClick(() => this.stack.pushPath({ name: 'detail', param: item.group }))
          }
          .swipeAction({ end: this.deleteButton(() => this.deleteOne(item.id)) })
        }, (item: Message) => item.id)
      }
    }
  }

  @Builder
  groupList() {
    if (this.state.groups.length === 0) {
      this.emptyTip(this.s('empty_messages'))
    } else {
      NavList({ space: 10, hPadding: 10, scrollBarState: BarState.Auto,
        scroller: this.listScroller }) {
        LazyForEach(this.state.groupsSource, (item: GroupHead) => {
          ListItem() {
            this.groupRow(item)
          }
          // 右滑（start）设为已读：未读蓝色可点、已读灰色禁用；左滑删除
          .swipeAction({
            start: this.markReadButton(item),
            end: this.deleteButton(() => this.deleteGroup(item.head.group))
          })
        }, (item: GroupHead) => item.head.id)
      }
    }
  }

  @Builder
  groupRow(item: GroupHead) {
    Row() {
      Column() {
        Row() {
          Text(this.groupName(item.head.group))
            .fontSize(17)
            .fontWeight(700)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (item.count > 1) {
            Text(`${item.count}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ right: 8 })
          }
          Text(Message.timeText(item.head.createDate))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')

        Text(this.groupPreview(item.head))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
        .margin({ left: 6 })
    }
    .padding({ left: 16, right: 12, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(12)
    .clip(true)
    // 左缘状态竖条（与消息卡片一致）：未读绿色、已读灰色，对齐标题行
    .overlay(this.groupStatusBar(item), {
      align: Alignment.TopStart,
      offset: { x: 0, y: 14 }
    })
    .onClick(() => this.stack.pushPath({ name: 'detail', param: item.head.group }))
  }

  // 分组行左缘竖条：未读绿色（呼吸）、已读灰色
  @Builder
  groupStatusBar(item: GroupHead) {
    Row()
      .width(4)
      .height(18)
      .borderRadius(2)
      .backgroundColor(item.unread > 0 ? $r('app.color.unread_bar') : $r('app.color.read_bar'))
      .opacity(item.unread > 0 ? this.groupBreath : 1)
  }

  private groupPreview(msg: Message): string {
    const parts: string[] = [];
    if (msg.title) {
      parts.push(msg.title);
    }
    if (msg.body) {
      parts.push(msg.body);
    }
    return parts.join(this.s('title_body_separator'));
  }

  // 双击卡片：整屏覆盖展示完整内容
  private openDetailCover(m: Message): void {
    this.detailMsg = m;
    this.showDetail = true;
  }

  // 全屏阅读层：标题/正文/链接完整展示，可滚动、可选择复制；右上 ✕ 关闭
  @Builder
  detailCover() {
    if (this.detailMsg) {
      MessageReader({
        message: this.detailMsg,
        onClose: (): void => {
          this.showDetail = false;
        }
      })
    }
  }
}
