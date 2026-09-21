import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, UIContext } from '@kit.ArkUI';
import { pushService, AAID, pushCommon } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';
import { messageStore } from '../model/DBTools';
import { PendingItem, pendingDrain } from '../model/PendingStore';
import { MessagesState } from '../model/MessagesState';
import { Message } from '../model/Message';
import { setPushReceiverForeground } from '../model/PushReceiver';
import { appStore, hydrateAppStore } from '../store/AppStore';
import { AppActions } from '../store/AppActions';
import { getDeviceId } from '../tools/DeviceId';
import { CryptoConfigFactory } from '../model/CryptoConfig';
import { serverRegistrar, ServerRegistrar } from '../model/ServerRegistrar';
import { ServerInfo } from '../model/ServerInfo';
import { util } from '@kit.ArkTS';
import { resByName, defaultGroup } from '../tools/I18n';
import { uiState } from '../model/UIState';
import { messageLocator } from '../model/MessageLocator';
import { tabsController } from '../model/TabsController';
import { checkClipboardQuickSend, resetQuickClipboardCheck } from '../tools/QuickClipboard';
import { setupCloudHistory } from '../tools/CloudHistory';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  // 主窗口 UIContext（onWindowStageCreate 后可用），用于回前台弹确认框
  private uiCtx: UIContext | null = null;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    await messageStore.init(this.context);
    await messageStore.deleteExpired();
    await this.drainPending();
    // 点击通知携带 id/url：发布定位命令（冷启动默认即在消息 Tab）
    this.handleNotificationClick(want);

    // Preferences 无 UI 实例要求，在 loadContent 前完成恢复，页面挂载时状态已就位
    await hydrateAppStore(this.context);
    // 无任何加密配置时补内置默认（对应 iOS 空列表塞 .data），保证注册签名可用
    if (appStore.getState().cryptoConfigs.length === 0) {
      await appStore.dispatch(AppActions.addCryptoConfig(CryptoConfigFactory.defaultConfig()));
    }
    // 内置项刷成与 iOS 一致的默认 key/iv（修早期版本持久化的示例 IV）
    await appStore.dispatch(AppActions.syncBuiltinCryptoConfig());
    await this.setupStore();
    // 云数据库历史服务器：初始化 Account Kit 凭证桥接
    // 云数据库历史服务器：读取 rawfile 中的 AGC 配置并初始化匿名认证
    const agcBytes: Uint8Array = this.context.resourceManager.getRawFileContentSync('agconnect-services.json');
    const agcJson: string = new util.TextDecoder().decodeToString(agcBytes);
    setupCloudHistory(this.context, agcJson);
  }

  // 首启灌种子、拉取推送 token/AAID、向所有服务器注册设备；变更一律 dispatch 落盘
  async setupStore(): Promise<void> {
    const state = appStore.getState();
    const deviceId: string = await getDeviceId(this.context);
    serverRegistrar.init(deviceId);

    if (state.firstStart) {
      await this.seedExamples();
      await appStore.dispatch(AppActions.setFirstStart(false));
    }

    let token: string = '';
    try {
      token = await pushService.getToken();
      await appStore.dispatch(AppActions.setPushToken(token));
      hilog.info(DOMAIN, TAG, `pushToken: ${token}`);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, `getToken failed: ${e.code} ${e.message}`);
    }



    try {
      const aaid: string = await AAID.getAAID();
      await appStore.dispatch(AppActions.setDeviceId(aaid));
      this.bindAppProfileId(aaid);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, `getAAID failed: ${e.code} ${e.message}`);
    }

    if (token) {
      await this.registerServers(deviceId, token);
    }

    // 监听 Push Kit 主动刷新 token（设备跨境等场景）：更新落盘并向已有服务器重注册
    try {
      pushService.on('tokenUpdate', this, (newToken: string): void => {
        this.handleTokenUpdate(newToken);
      });
      hilog.info(DOMAIN, TAG, 'tokenUpdate listener registered');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, `tokenUpdate on failed: ${e.code} ${e.message}`);
    }
  }

  // token 被 Push Kit 刷新：持久化新 token；无服务器时无需处理（下次启动注册流程会带上），
  // 有服务器时并发重注册并更新在线状态
  private handleTokenUpdate(newToken: string): void {
    hilog.info(DOMAIN, TAG, `tokenUpdate: ${newToken}`);
    if (!newToken || newToken === appStore.getState().pushToken) {
      return;
    }
    appStore.dispatch(AppActions.setPushToken(newToken));
    const servers: ServerInfo[] = appStore.getState().servers;
    if (servers.length === 0) {
      return;
    }
    serverRegistrar.registerAll(servers, newToken).then((results: ServerInfo[]): void => {
      results.forEach((s: ServerInfo): void => {
        appStore.dispatch(AppActions.setServerStatus(s.id, s.status));
      });
    }).catch((err: BusinessError): void => {
      hilog.error(DOMAIN, TAG, `tokenUpdate re-register failed: ${err.code} ${err.message}`);
    });
  }

  // 对应 iOS：无服务器时向默认服务器认领 deviceKey 再注册；已有则并发重注册
  async registerServers(deviceId: string, token: string): Promise<void> {
    const servers: ServerInfo[] = appStore.getState().servers;
    if (servers.length === 0) {
      const claimed: boolean =
        await serverRegistrar.claimKey(ServerRegistrar.DEFAULT_SERVER, deviceId);
      if (claimed) {
        const fresh = new ServerInfo();
        fresh.id = util.generateRandomUUID(false);
        fresh.url = ServerRegistrar.DEFAULT_SERVER;
        fresh.key = deviceId;
        const registered: ServerInfo = await serverRegistrar.register(fresh, token);
        if (registered.status > 0) {
          await appStore.dispatch(AppActions.addServer(registered));
        }
      }
      return;
    }

    // 已有服务器：并发重注册刷新在线状态，并向默认服务器续约 deviceKey
    const results: ServerInfo[] = await serverRegistrar.registerAll(servers, token);
    for (let i = 0; i < results.length; i++) {
      await appStore.dispatch(AppActions.setServerStatus(results[i].id, results[i].status));
    }
    await serverRegistrar.claimKey(ServerRegistrar.DEFAULT_SERVER, deviceId);
  }


  bindAppProfileId( profileId: string): void {
    pushService.bindAppProfileId(pushCommon.AppProfileType.PROFILE_TYPE_APPLICATION_ACCOUNT, profileId).then(() => {
      hilog.info(DOMAIN, 'testTag', 'Succeeded in binding app profile id');
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to bind app profile id: %{public}d %{public}s', err.code, err.message);
    });
  }

  // remoteNotification 扩展跨进程写入的消息，在启动/回前台时入库
  async drainPending(): Promise<void> {
    const items: PendingItem[] = await pendingDrain(this.context);
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      try {
        if (item.action === 'delete') {
          await messageStore.delete(item.id ?? '');
        } else {
          await messageStore.upsert(new Message(item));
        }
      } catch (e) {
        hilog.error(DOMAIN, TAG, `drain item failed: ${(e as Error).message}`);
      }
    }
    if (items.length > 0) {
      await MessagesState.instance?.refresh();
    }
  }

  async seedExamples(): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    const ctx = this.context;
    const s = (name: string, ...args: Array<string | number>): string => resByName(ctx, name, ...args);
    // 固定 id:即使 firstStart 意外重置,INSERT OR REPLACE 也不会产生重复种子
    await messageStore.upsert(new Message({
      id: 'seed-welcome',
      group: defaultGroup(ctx),
      title: s('welcome_title'),
      body: s('welcome_body'),
      createDate: now,
      ttl: -1,
    }));
    await messageStore.upsert(new Message({
      id: 'seed-alert',
      group: s('seed_group_ops'),
      title: s('seed_alert_title'),
      body: s('seed_alert_body'),
      url: 'https://wzs.app',
      createDate: now - 60,
      ttl: -1,
    }));

  }

  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onNewWant');
    // 必须先等 PendingStore 的推送消息入库再定位；否则 getById 早于 upsert，按 id 查不到
    await this.drainPending();
    this.handleNotificationClick(want);
  }

  // 解析通知 want.parameters 的 id/url 并发布定位命令。
  // 温启动(uiCtx 已存在)先切回消息 Tab；冷启动(uiCtx 为 null)默认已在消息 Tab
  private handleNotificationClick(want: Want): void {
    const id: string = (want.parameters?.['id'] as string) ?? '';
    if (!id) {
      hilog.info(DOMAIN, TAG, 'notification click: no id in want.parameters');
      return;
    }
    const url: string = (want.parameters?.['url'] as string) ?? '';
    hilog.info(DOMAIN, TAG,
      `notification click: id=${id} url=${url} warm=${this.uiCtx !== null}`);
    if (this.uiCtx !== null) {
      tabsController.changeIndex(0);
    }
    messageLocator.request(id, url);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    // 全屏布局:内容延伸到状态栏/手势条下,由 HdsNavigation 标题栏与悬浮 TabBar 自己处理安全区
    try {
      const mainWindow = windowStage.getMainWindowSync();
      await mainWindow.setWindowLayoutFullScreen(true);
      // 全屏生效后同步测量一次避让区（loadContent 之前，页面首帧即拿到正确高度，无占位跳动），
      // 再订阅变化：旋转/折叠/多窗与手势导航切换都会实时更新
      this.measureAvoidAreas(mainWindow);
      mainWindow.on('avoidAreaChange', (): void => {
        this.measureAvoidAreas(mainWindow);
      });
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          return;
        }
        // 内容加载完成后 UIContent 才存在，此时再缓存 UIContext 供回前台弹窗使用
        this.uiCtx = windowStage.getMainWindowSync().getUIContext();
        // 冷启动时 onForeground 可能早于内容加载（uiCtx 为空），这里补一次剪贴板快捷发送检测
        setTimeout((): void => {
          checkClipboardQuickSend(this.uiCtx, this.context);
        }, 600);
        notificationManager.requestEnableNotification(this.context).then(() => {
          hilog.info(DOMAIN, TAG, '[ANS] requestEnableNotification success');
        }).catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG,
            `[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
        });
      });

      await mainWindow.setWindowSystemBarProperties({
        navigationBarColor: Color.Transparent.toString(),
        statusBarColor:  Color.Transparent.toString(),
      })



    } catch (error) {
      console.error(error)
    }

  }

  // 测量状态栏/手势条高度(vp)写入全局 uiState；底部取系统避让区与手势条的较大值，兼容三键导航
  private measureAvoidAreas(win: window.Window): void {
    try {
      const uiContext = win.getUIContext();
      const system = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const indicator = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      uiState.statusBarHeight = uiContext.px2vp(system.topRect.height);
      uiState.navIndicatorHeight =
        Math.max(uiContext.px2vp(system.bottomRect.height), uiContext.px2vp(indicator.bottomRect.height));
    } catch (err) {
      hilog.error(DOMAIN, TAG, `measureAvoidAreas failed: ${(err as BusinessError).message}`);
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    setPushReceiverForeground(true);
    // 回前台：收扩展归档 + 清理过期 + 刷新页面；不主动置已读，保留未读标记供用户查看
    this.drainPending();
    MessagesState.instance?.refresh();
    // 快捷发送：检测剪贴板（延迟等窗口与状态就绪），自动发送或弹窗确认
    setTimeout((): void => {
      checkClipboardQuickSend(this.uiCtx, this.context);
    }, 600);
  }

  onBackground(): void {
    setPushReceiverForeground(false);
    resetQuickClipboardCheck();
    // 进后台：列表模式全部置已读；分组模式保留未读，由详情页返回或行右滑清理
    if (!appStore.getState().showGroup) {
      messageStore.markAllRead();
    }
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
