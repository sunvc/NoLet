import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { HdsNavDestination, HdsListItemCard, PrefixCustomBuilder } from '@kit.UIDesignKit';
import { hdsTitleBar } from '../components/HdsTitle';
import { NavList, TITLE_BAR_HEIGHT_MINI } from '../components/NavList';
import { Haptics } from '../tools/Haptics';
import { AppStoreModel } from '../model/AppStoreModel';
import { appStore, AppActions } from '../store/AppStore';
import { serverRegistrar } from '../model/ServerRegistrar';
import { ServerInfo } from '../model/ServerInfo';
import { CloudServer } from '../model/CloudServer';
import { fetchHistory, backfill, deleteHistory, syncServer, CloudHistoryResult } from '../tools/CloudHistory';
import { resByName } from '../tools/I18n';

/// 历史服务器页：展示已同步到云数据库的服务器（按时间倒序），
/// 点击行直接注册到本地（本地无重合时），左滑删除云端记录
@ComponentV2
export struct HistoryServersView {
  @Local prop: AppStoreModel = appStore.getState();
  @Local records: CloudServer[] = [];
  @Local loading: boolean = false;
  // 正在注册到本地的记录 id（与 ForEach key 同值），空串表示空闲
  @Local registeringId: string = '';
  private listScroller: ListScroller = new ListScroller();
  // 删除确认回调
  private pendingRecord: CloudServer | null = null;

  aboutToAppear(): void {
    this.reload();
  }

  private s(name: string, ...args: Array<string | number>): string {
    return resByName(this.getUIContext().getHostContext() as common.Context, name, ...args);
  }

  private recordId(record: CloudServer): string {
    return `${record.user}|${record.key}|${record.url}`;
  }

  /// 补偿同步本地服务器后，拉取云端历史
  async reload(): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    try {
      const result: CloudHistoryResult = await backfill(this.prop.servers);
      if (result.reason === 'not_logged_in') {
        this.showLoginRequiredDialog();
      }
      this.records = await fetchHistory();
    } catch (e) {
      console.error(`history reload failed: ${(e as BusinessError).message}`);
    } finally {
      this.loading = false;
    }
  }

  /// 无 unionID（未登录华为账号）时提示用户去「关于」页登录
  private showLoginRequiredDialog(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: this.s('login_required_title'),
      message: this.s('history_login_required'),
      buttons: [
        { text: this.s('action_ok'), color: '#007AFF' }
      ]
    }).catch((): void => {});
  }

  /// 点击行：本地已有同 URL+KEY 的服务器则提示，否则认领并注册到本地
  async registerRecord(record: CloudServer): Promise<void> {
    if (this.registeringId !== '') return;
    const url: string = record.url;
    const key: string = record.key;
    if (this.prop.servers.some((x: ServerInfo): boolean => x.url === url && x.key === key)) {
      this.toast(this.s('server_exists'));
      return;
    }
    this.registeringId = this.recordId(record);
    this.toast(this.s('registering'));
    try {
      // 带 key 时先 GET 认领/校验（与服务器页添加自定义服务器一致）；空 key 由服务端注册时下发
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
      const registered: ServerInfo = await serverRegistrar.register(s, this.prop.pushToken);
      if (registered.status <= 0) {
        this.toast(this.s('err_register'));
        return;
      }
      appStore.dispatch(AppActions.addServer(registered));
      this.checkOne(registered);
      // 无 key 记录注册后服务端下发了 key，回写云端一条
      syncServer(registered);
      this.toast(this.s('server_added'));
    } finally {
      this.registeringId = '';
    }
  }

  // GET {url}/healthz：注册成功后立即探活一次，状态点反映真实结果
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
      hilog.error(0x0000, 'HistoryServers', `healthz failed for ${s.url}: ${err.code} ${err.message}`);
      s.status = -1;
    } finally {
      req.destroy();
    }
  }

  /// 左滑删除：先确认再删云端，成功后本地移除
  askDelete(record: CloudServer): void {
    this.pendingRecord = record;
    this.getUIContext().getPromptAction().showDialog({
      title: this.s('history_delete_title'),
      message: this.s('history_delete_message', record.url),
      buttons: [
        { text: this.s('action_cancel'), color: '#8E8E93' },
        { text: this.s('action_delete'), color: '#FF3B30' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse): void => {
      if (result.index === 1 && this.pendingRecord !== null) {
        this.doDelete(this.pendingRecord);
      }
    }).catch((): void => {});
  }

  async doDelete(record: CloudServer): Promise<void> {
    this.pendingRecord = null;
    const result = await deleteHistory(record);
    if (result.ok) {
      // 主键相同的行移除；正常只有一条
      this.records = this.records.filter(
        (x: CloudServer): boolean => !(x.user === record.user && x.key === record.key && x.url === record.url));
    } else {
      this.toast(this.s('history_delete_failed'));
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({
      message,
      duration: 2000,
      showMode: promptAction.ToastShowMode.DEFAULT,
      bottom: 120
    });
    Haptics.success();
  }

  private formatDate(d: Date): string {
    const f = new Intl.DateTimeFormat(undefined, {
      month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit'
    });
    try {
      return f.format(d);
    } catch {
      return '';
    }
  }

  // 左侧时钟彩色方块
  @Builder
  historyIcon(record: CloudServer) {
    Stack() {
      SymbolGlyph($r('sys.symbol.clock'))
        .fontSize(18)
        .fontColor([Color.White])
    }
    .width(30)
    .height(30)
    .borderRadius(8)
    .backgroundColor('#5856D6')
  }

  // B 区：URL 粗体 + KEY/时间 次行，右侧添加按钮（注册中转菊花）
  @Builder
  historyText(record: CloudServer) {
    Row() {
      Column() {
        Text(record.url)
          .fontSize(16)
          .fontWeight(600)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row() {
          Text(record.key ? record.key : this.s('server_no_key'))
            .fontSize(13)
            .fontColor(record.key ? $r('app.color.text_secondary') : $r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(this.formatDate(record.createDate))
            .fontSize(13)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.registeringId === this.recordId(record)) {
        LoadingProgress()
          .width(22)
          .height(22)
          .color($r('app.color.text_primary'))
          .padding(9)
      } else {
        SymbolGlyph($r('sys.symbol.plus_circle'))
          .fontSize(20)
          .fontColor([$r('app.color.text_primary')])
          .padding(10)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  historyCard(record: CloudServer) {
    HdsListItemCard({
      prefixItem: new PrefixCustomBuilder((): void => { this.historyIcon(record); }),
      textItem: { customBuilder: (): void => { this.historyText(record); } },
      cardBackgroundColor: $r('app.color.bg_card'),
      onClick: (): void => { this.registerRecord(record); }
    })
  }

  @Builder
  loadingTip() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(34)
        .height(34)
        .color($r('app.color.text_secondary'))
      Text(this.s('history_loading'))
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  emptyTip() {
    Column() {
      Blank()
      Text(this.prop.huaweiUnionID
        ? this.s('history_empty')
        : this.s('history_login_required'))
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
      if (this.loading) {
        this.loadingTip()
      } else if (this.records.length === 0) {
        this.emptyTip()
      } else {
        NavList({ space: 8, hPadding: 0, titleHeight: TITLE_BAR_HEIGHT_MINI, topGap: 0,
          scroller: this.listScroller }) {
          ForEach(this.records, (record: CloudServer) => {
            ListItem() {
              this.historyCard(record)
            }
            .swipeAction({
              end: this.deleteButton(record)
            })
          }, (record: CloudServer): string => this.recordId(record))
        }
      }
    }
    .titleBar(hdsTitleBar($r('app.string.title_history')))
    .bindToScrollable([this.listScroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  deleteButton(record: CloudServer) {
    Button(this.s('action_delete'))
      .backgroundColor('#FF3B30')
      .fontColor(Color.White)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .margin({ left: 16, right: 16 })
      .onClick((): void => this.askDelete(record))
  }
}
