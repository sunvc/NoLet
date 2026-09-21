// 点击推送通知后的"定位某条消息"一次性命令 + 高亮状态。
// EntryAbility 在 onCreate(冷启动)/onNewWant(温启动) 发布；MessagesView 用
// @Monitor(温启动)/aboutToAppear 补消费(冷启动) 接住并执行定位。
@ObservedV2
export class MessageLocator {
  // 定位请求计数：每次 request +1，MessagesView @Monitor 据此响应（温启动）
  @Trace locateTick: number = 0;
  // 需要高亮的消息 id：MessageCard 在 build 中读取后显示整块绿色边框
  @Trace highlightId: string = '';

  // 最近一次待处理负载。冷启动发布时 MessagesView 尚未挂载，由其 aboutToAppear 补消费
  private pendingId: string = '';
  private pendingUrl: string = '';
  private hasPendingFlag: boolean = false;

  // EntryAbility 调用：记录负载并触发 tick
  request(id: string, url: string): void {
    this.pendingId = id;
    this.pendingUrl = url;
    this.hasPendingFlag = true;
    this.locateTick++;
  }

  // MessagesView 取出待处理负载并清除；无则返回 null
  consumePending(): PendingLocate | null {
    if (!this.hasPendingFlag) return null;
    const result: PendingLocate = { id: this.pendingId, url: this.pendingUrl };
    this.hasPendingFlag = false;
    return result;
  }

  startHighlight(id: string): void {
    this.highlightId = id;
  }

  clearHighlight(): void {
    this.highlightId = '';
  }
}

export interface PendingLocate {
  id: string;
  url: string;
}

export const messageLocator = new MessageLocator();
