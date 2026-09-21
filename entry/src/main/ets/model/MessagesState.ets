import { Message } from './Message';
import { messageStore, Snapshot, GroupHead } from './DBTools';
import { BasicDataSource } from './DataSource';

// 页面共享的消息状态单例（@ObservedV2），DB 变更后调用 reload。
// 后台推送回调（PushReceiver）与 UI 同进程时直接通过 instance 刷新；
// remoteNotification 扩展走 PendingStore，由 EntryAbility drain 后刷新。
@ObservedV2
export class MessagesState {
  static instance: MessagesState | null = null;
  private loaded = false;

  @Trace flat: Message[] = [];
  @Trace groups: GroupHead[] = [];
  @Trace total: number = 0;
  @Trace unread: number = 0;

  // 列表改用 LazyForEach：以数据源为单一事实，reload 时整表 replaceAll 触发框架按 key 复用
  readonly flatSource: BasicDataSource<Message> = new BasicDataSource<Message>();
  readonly groupsSource: BasicDataSource<GroupHead> = new BasicDataSource<GroupHead>();

  constructor() {
    MessagesState.instance = this;
  }

  static get shared(): MessagesState {
    if (!MessagesState.instance) MessagesState.instance = new MessagesState();
    return MessagesState.instance;
  }

  async reload(): Promise<void> {
    const list = await messageStore.latest();
    const snapshot: Snapshot = await messageStore.snapshot();
    // LazyForEach 按 id/group 复用组件：同 key 必须就地更新原对象，直接整体换数组
    // 会让复用行仍绑定旧对象，已读等状态变化刷不到 UI
    this.syncFlat(list);
    this.syncGroups(snapshot.groups);
    this.flatSource.replaceAll(this.flat);
    this.groupsSource.replaceAll(this.groups);
    this.total = snapshot.total;
    this.unread = snapshot.unread;
    this.loaded = true;
  }

  // 同 id 消息把最新字段 copyFrom 回旧对象，新 id 用新对象，消失的 id 丢弃
  private syncFlat(latest: Message[]): void {
    const oldById = new Map<string, Message>();
    this.flat.forEach((m: Message): void => {
      oldById.set(m.id, m);
    });
    this.flat = latest.map((m: Message): Message => {
      const existing = oldById.get(m.id);
      if (existing) {
        existing.copyFrom(m);
        return existing;
      }
      return m;
    });
  }

  // 同分组保留原 GroupHead，就地写回头条/未读/总数；新分组用新对象
  private syncGroups(latest: GroupHead[]): void {
    const oldByGroup = new Map<string, GroupHead>();
    this.groups.forEach((g: GroupHead): void => {
      oldByGroup.set(g.head.group, g);
    });
    this.groups = latest.map((g: GroupHead): GroupHead => {
      const existing = oldByGroup.get(g.head.group);
      if (existing) {
        existing.head.copyFrom(g.head);
        existing.unread = g.unread;
        existing.count = g.count;
        return existing;
      }
      return g;
    });
  }

  async ensureLoaded(): Promise<void> {
    if (!this.loaded) await this.reload();
  }

  // 应用收到推送 / 回前台时：处理过期、统计与列表
  async refresh(): Promise<void> {
    await messageStore.deleteExpired();
    await this.reload();
  }
}
