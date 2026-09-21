import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Haptics } from '../tools/Haptics';
import { promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { serverRegistrar, ServerRegistrar } from '../model/ServerRegistrar';
import { ServerInfo } from '../model/ServerInfo';
import { getDeviceId } from '../tools/DeviceId';
import { syncServer } from '../tools/CloudHistory';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { HdsNavDestination, HdsListItemCard, PrefixCustomBuilder } from '@kit.UIDesignKit';
import { resByName } from '../tools/I18n';

// 服务器配置页：卡片展示 URL / KEY，右滑重置 KEY，左滑删除；
// 标题栏两个按钮：皇冠添加官方服务器（一键认领注册）、笔添加自定义服务器（URL + 可选 KEY）
@ComponentV2
export struct ServersView {
  // 扫码 nolet://server 深链进入时预填（设置页 pushPath 传入）
  @Param prefillUrl: string = '';
  @Param prefillKey: string = '';
  /// 进入历史服务器页用的路由栈（Settings 页注入）
  @Param stack: NavPathStack | null = null;
  @Local prop: AppStoreModel = appStore.getState();
  @Local showAdd: boolean = false;
  @Local inputUrl: string = '';
  @Local inputKey: string = '';
  // 注册请求进行中：禁用保存按钮、锁定输入
  @Local saving: boolean = false;
  // 重置 KEY 后用它收起已露出的滑动操作区
  private scroller: ListScroller = new ListScroller();

  aboutToAppear(): void {
    this.checkAll();
    // 扫码进入：直接弹出添加服务器 Sheet 并预填
    if (this.prefillUrl) {
      this.inputUrl = this.prefillUrl;
      this.inputKey = this.prefillKey;
      this.showAdd = true;
    }
  }

  // GET {url}/healthz：健康检查 2xx 即在线
  async checkOne(s: ServerInfo): Promise<void> {
    s.status = 0;
    const req = http.createHttp();
    try {
      const resp = await req.request(`${s.url}/healthz`, {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
        usingProtocol: http.HttpProtocol.HTTP1_1,
      });
      s.status = resp.responseCode >= 200 && resp.responseCode < 300 ? 1 : -1;
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'ServersView', `healthz failed for ${s.url}: ${err.code} ${err.message}`);
      s.status = -1;
    } finally {
      req.destroy();
    }
  }

  checkAll(): void {
    this.prop.servers.forEach((s: ServerInfo): void => { this.checkOne(s); });
  }

  // 正常分组：注册/探测状态 > 0（与 iOS item.status > 0 一致，core 可能为其他正值）；
  // 离线(-1)与检测中(0)归入故障分组
  private normalServers(): ServerInfo[] {
    return this.prop.servers.filter((s: ServerInfo): boolean => s.status > 0);
  }

  private faultServers(): ServerInfo[] {
    return this.prop.servers.filter((s: ServerInfo): boolean => s.status <= 0);
  }

  // ForEach.onMove 回调：from/to 是同一状态分组数据源内的下标，
  // 映射回 servers 数组的全局下标后落盘（同子集移动，按下标先移除后插入结果一致）
  private onGroupMove(group: ServerInfo[], from: number, to: number): void {
    if (from === to || from < 0 || to < 0 || from >= group.length || to >= group.length) {
      return;
    }
    const all: ServerInfo[] = this.prop.servers;
    const fromId: string = group[from].id;
    const toId: string = group[to].id;
    let aiFrom: number = -1;
    let aiTo: number = -1;
    for (let i = 0; i < all.length; i++) {
      if (all[i].id === fromId) aiFrom = i;
      if (all[i].id === toId) aiTo = i;
    }
    if (aiFrom >= 0 && aiTo >= 0) {
      appStore.dispatch(AppActions.reorderServer(aiFrom, aiTo));
    }
  }

  normalizeUrl(raw: string): string {
    let u: string = raw.trim().replace(/\/+$/, '');
    if (!/^https?:\/\//i.test(u)) {
      u = `https://${u}`;
    }
    return u;
  }

  // 官方服务器：以本机 deviceId 作为 KEY 认领并注册（与首启自动注册流程一致）
  async addOfficialServer(): Promise<void> {
    if (this.saving) return;
    const url: string = ServerRegistrar.DEFAULT_SERVER;
    if (this.prop.servers.some((x: ServerInfo): boolean => x.url === url)) {
      this.toast(this.s('server_exists'));
      return;
    }
    const ctx: common.Context = this.getUIContext().getHostContext() as common.Context;
    this.saving = true;
    this.toast(this.s('registering'));
    try {
      const deviceId: string = await getDeviceId(ctx);
      serverRegistrar.init(deviceId);
      const claimed: boolean = await serverRegistrar.claimKey(url, deviceId);
      if (!claimed) {
        this.toast(this.s('err_claim'));
        return;
      }
      const s: ServerInfo = new ServerInfo();
      s.id = util.generateRandomUUID(false);
      s.url = url;
      s.key = deviceId;
      const registered: ServerInfo = await serverRegistrar.register(s, this.prop.pushToken);
      if (registered.status <= 0) {
        this.toast(this.s('err_register'));
        return;
      }
      appStore.dispatch(AppActions.addServer(registered));
      this.checkOne(registered);
      // 同步历史服务器到云端（失败静默，不影响添加流程）
      syncServer(registered);
      this.toast(this.s('server_added'));
    } finally {
      this.saving = false;
    }
  }

  openAdd(): void {
    this.inputUrl = '';
    this.inputKey = '';
    this.saving = false;
    this.showAdd = true;
  }

  // 带占位符的动态文案取当前语言资源
  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  async saveServer(): Promise<void> {
    if (this.saving) return;
    const raw: string = this.inputUrl.trim();
    if (!raw) {
      this.toast(this.s('err_url_required'));
      return;
    }
    const url: string = this.normalizeUrl(raw);
    const key: string = this.inputKey.trim();
    const token: string = this.prop.pushToken;

    if (this.prop.servers.some((x: ServerInfo): boolean => x.url === url && x.key === key)) {
      this.toast(this.s('server_exists'));
      return;
    }

    this.saving = true;
    try {
      // 带 key 时先 GET 认领/校验（对应 iOS restore）；空 key 直接 POST，由服务端下发
      if (key) {
        const claimed: boolean = await serverRegistrar.claimKey(url, key);
        if (!claimed) {
          this.toast(this.s('err_claim'));
          return;
        }
      }

      const s: ServerInfo = new ServerInfo();
      s.id = util.generateRandomUUID(false);
      s.url = url;
      s.key = key;
      const registered: ServerInfo = await serverRegistrar.register(s, token);
      if (registered.status <= 0) {
        this.toast(this.s('err_register'));
        return;
      }

      appStore.dispatch(AppActions.addServer(registered));
      this.showAdd = false;
      // 立即探活一次，状态点反映真实 /healthz 结果（reducer 入存的就是 registered 同一实例）
      this.checkOne(registered);
      // 同步历史服务器到云端（失败静默）
      syncServer(registered);
      this.toast(this.s('server_added'));
    } finally {
      this.saving = false;
    }
  }

  confirmDelete(s: ServerInfo): void {
    this.confirm(this.s('delete_server_title'), this.s('delete_server_message', s.url), (): void => {
      appStore.dispatch(AppActions.removeServer(s.id));
    });
  }

  // 重置：以空 key 重新 POST 注册，服务端生成并下发新 key；失败保留原 key
  confirmReset(s: ServerInfo): void {
    this.confirm(this.s('reset_key_title'), this.s('reset_key_message', s.url), (): void => {
      this.doReset(s);
    });
  }

  async doReset(s: ServerInfo): Promise<void> {
    this.scroller.closeAllSwipeActions();

    const copy: ServerInfo = new ServerInfo();
    copy.id = s.id;
    copy.url = s.url;
    copy.group = s.group;
    copy.key = '';

    const registered: ServerInfo = await serverRegistrar.register(copy, this.prop.pushToken);
    if (registered.status > 0 && registered.key) {
      appStore.dispatch(AppActions.setServerKey(s.id, registered.key));
      appStore.dispatch(AppActions.setServerStatus(s.id, registered.status));
      // 云端历史追加新 key 行（主键含 key，旧行保留）
      const historyCopy: ServerInfo = new ServerInfo();
      historyCopy.url = registered.url;
      historyCopy.key = registered.key;
      syncServer(historyCopy);
      this.toast(this.s('key_reset'));
    } else {
      this.toast(this.s('reset_failed'));
    }
  }

  /// 打开历史服务器页
  openHistory(): void {
    if (this.stack !== null) {
      this.stack.pushPath({ name: 'historyServers' });
    }
  }

  // 复制 域名/KEY 完整地址（url 已规范化、无尾部斜杠）
  copyServer(s: ServerInfo): void {
    if (!s.key) {
      this.toast(this.s('server_no_key_toast'));
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, `${s.url}/${s.key}`);
    pasteboard.getSystemPasteboard().setData(data);
    this.toast(this.s('server_copied'));
  }

  private confirm(title: string, message: string, onOk: () => void): void {
    this.getUIContext().getPromptAction().showDialog({
      title,
      message,
      buttons: [
        { text: this.s('action_cancel'), color: $r('app.color.text_secondary') },
        { text: this.s('action_ok'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1) onOk();
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

  private statusColor(s: ServerInfo): string {
    return s.status > 0 ? '#34C759' : s.status === -1 ? '#FF3B30' : '#8E8E93';
  }

  // 左侧 externaldrive 彩色方块，颜色即状态；点击重新探测
  @Builder
  serverIcon(s: ServerInfo) {
    Stack() {
      SymbolGlyph($r('sys.symbol.externaldrive'))
        .fontSize(18)
        .fontColor([Color.White])
    }
    .width(30)
    .height(30)
    .borderRadius(8)
    .backgroundColor(this.statusColor(s))
    .onClick((): void => { this.checkOne(s); })
  }

  // B 区内容：URL + KEY 两行，右侧复制 域名/KEY 按钮
  @Builder
  serverText(s: ServerInfo) {
    Row() {
      Column() {
        Text(s.url)
          .fontSize(16)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(s.key ? s.key : this.s('server_no_key'))
          .fontSize(13)
          .fontColor(s.key ? $r('app.color.text_secondary') : $r('app.color.text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.doc'))
        .fontSize(20)
        .fontColor([$r('app.color.text_primary')])
        .padding(10)
        .onClick((): void => this.copyServer(s))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  serverCard(s: ServerInfo) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.serverIcon(s); }),
      textItem: { customBuilder: (): void => { this.serverText(s); } },
      cardBackgroundColor: $r('app.color.bg_card')
    })
  }

  // 分组标题：小号灰色，与卡片内容左缘对齐（HDS 卡片自带 16vp 外边距）
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

  // 滑动操作按钮：右滑(start)重置、左滑(end)删除
  @Builder
  swipeButton(label: string, color: string, mLeft: number, mRight: number, action: () => void) {
    Button(label)
      .backgroundColor(color)
      .fontColor(Color.White)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .margin({ left: mLeft, right: mRight })
      .onClick(action)
  }

  @Builder
  emptyTip() {
    Column() {
      Blank()
      Text($r('app.string.empty_servers'))
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
    // padding 只能写一次：分次调用后者会整体覆盖前者，之前导致左右边距丢失、表单顶满屏幕；
    // top 36 避开系统拖拽条与圆角，right 留出右上角关闭按钮的空间
    Column({ space: 14 }) {
      Text($r('app.string.add_custom_server'))
        .fontSize(18)
        .fontWeight(700)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 4 })
      TextInput({ placeholder: $r('app.string.server_url_placeholder'), text: $$this.inputUrl })
        .key('serverUrlInput')
        .height(48)
        .backgroundColor($r('app.color.bg_chip'))
        .borderRadius(10)
        .padding({ left: 14, right: 14 })
        .enabled(!this.saving)
        .enterKeyType(EnterKeyType.Next)
        .onSubmit((): void => this.getUIContext().getFocusController().requestFocus('serverKeyInput'))
      TextInput({ placeholder: $r('app.string.server_key_placeholder'), text: $$this.inputKey })
        .key('serverKeyInput')
        .height(48)
        .backgroundColor($r('app.color.bg_chip'))
        .borderRadius(10)
        .padding({ left: 14, right: 14 })
        .enabled(!this.saving)
        .enterKeyType(EnterKeyType.Done)
        .onSubmit((): void => {
          this.saveServer();
        })
      Button() {
        Row({ space: 8 }) {
          if (this.saving) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(Color.White)
          }
          Text(this.saving ? this.s('registering') : this.s('action_save'))
        }
        .justifyContent(FlexAlign.Center)
      }
        .width('100%')
        .height(48)
        .borderRadius(10)
        .backgroundColor(this.saving ? '#7AB8D4' : '#1698CE')
        .enabled(!this.saving)
        .fontColor(Color.White)
        .fontSize(16)
        .margin({ top: 4 })
        .onClick((): void => {
          this.saveServer();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 36, bottom: 36 })
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    HdsNavDestination() {
      if (this.prop.servers.length === 0) {
        this.emptyTip()
      } else {
        // HDS 卡片自带 16vp 外边距，hPadding 设 0；滑动按钮 margin 16 与卡片边缘对齐
        // ForEach.onMove：长按卡片拖动排序（仅同一状态分组内）
        NavList({ space: 8, hPadding: 0, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
          scroller: this.scroller }) {
          if (this.normalServers().length > 0) {
            this.sectionHeader($r('app.string.section_normal'))
            ForEach(this.normalServers(), (s: ServerInfo) => {
              ListItem() {
                this.serverCard(s)
              }
              .swipeAction({
                start: this.swipeButton(this.s('action_reset'), '#FF9500', 16, 16, (): void => this.confirmReset(s)),
                end: this.swipeButton(this.s('action_delete'), '#FF3B30', 16, 16, (): void => this.confirmDelete(s))
              })
            }, (s: ServerInfo): string => s.id)
              .onMove((from: number, to: number): void => {
                this.onGroupMove(this.normalServers(), from, to);
              })
          }
          if (this.faultServers().length > 0) {
            this.sectionHeader($r('app.string.section_fault'))
            ForEach(this.faultServers(), (s: ServerInfo) => {
              ListItem() {
                this.serverCard(s)
              }
              .swipeAction({
                start: this.swipeButton(this.s('action_reset'), '#FF9500', 16, 16, (): void => this.confirmReset(s)),
                end: this.swipeButton(this.s('action_delete'), '#FF3B30', 16, 16, (): void => this.confirmDelete(s))
              })
            }, (s: ServerInfo): string => s.id)
              .onMove((from: number, to: number): void => {
                this.onGroupMove(this.faultServers(), from, to);
              })
          }
        }
      }
    }
    .titleBar(hdsTitleBar($r('app.string.title_servers'), [
      // 皇冠：添加官方服务器（一键认领注册）；笔：添加自定义服务器（URL + 可选 KEY）
      {
        content: {
          icon: $r('sys.symbol.crown_fill'),
          action: (): void => {
            this.addOfficialServer();
          }
        }
      },
      {
        content: {
          icon: $r('sys.symbol.square_and_pencil'),
          action: (): void => this.openAdd()
        }
      },
      // 时钟：历史服务器
      {
        content: {
          icon: $r('sys.symbol.clock'),
          action: (): void => this.openHistory()
        }
      }
    ]))
    .bindToScrollable([this.scroller])
    .bindSheet($$this.showAdd, this.addSheet(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true,
      backgroundColor: $r('app.color.bg_card')
    })
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }
}
