import { relationalStore } from '@kit.ArkData';

// iOS 转换过来的消息字段（华为侧仅支持这些）：
// createDate / ttl 均为 Unix 秒；ttl <= 0 为永久哨兵。
export interface MessageItem {
  id?: string;
  group?: string;
  createDate?: number;
  title?: string;
  body?: string;
  icon?: string;
  url?: string;
  image?: string;
  ttl?: number;
  read?: boolean;
}

@ObservedV2
export class Message implements MessageItem {
  @Trace id: string = '';
  @Trace group: string = '默认';
  @Trace createDate: number = Math.floor(Date.now() / 1000);
  @Trace title: string = '';
  @Trace body: string = '';
  @Trace icon: string = '';
  @Trace url: string = '';
  @Trace image: string = '';
  @Trace ttl: number = -1;
  @Trace read: boolean = false;

  constructor(data?: MessageItem) {
    if (data) {
      if (data.id !== undefined) this.id = data.id;
      if (data.group !== undefined) this.group = data.group;
      if (data.createDate !== undefined) this.createDate = data.createDate;
      if (data.title !== undefined) this.title = data.title;
      if (data.body !== undefined) this.body = data.body;
      if (data.icon !== undefined) this.icon = data.icon;
      if (data.url !== undefined) this.url = data.url;
      if (data.image !== undefined) this.image = data.image;
      if (data.ttl !== undefined) this.ttl = data.ttl;
      if (data.read !== undefined) this.read = data.read;
    }
  }

  // ForEach 按 id 复用组件时，就地把最新行数据写回同一对象，驱动 @Trace 刷新
  copyFrom(other: Message): void {
    this.id = other.id;
    this.group = other.group;
    this.createDate = other.createDate;
    this.title = other.title;
    this.body = other.body;
    this.icon = other.icon;
    this.url = other.url;
    this.image = other.image;
    this.ttl = other.ttl;
    this.read = other.read;
  }

  static fromResultSet(rs: relationalStore.ResultSet): Message {
    const str = (col: string): string => {
      const i = rs.getColumnIndex(col);
      return i < 0 || rs.isColumnNull(i) ? '' : rs.getString(i);
    };
    const msg = new Message({
      id: str('id'),
      group: str('group'),
      title: str('title'),
      body: str('body'),
      icon: str('icon'),
      url: str('url'),
      image: str('image'),
    });
    msg.createDate = rs.getLong(rs.getColumnIndex('createDate'));
    msg.ttl = rs.getLong(rs.getColumnIndex('ttl'));
    msg.read = rs.getLong(rs.getColumnIndex('read')) === 1;
    return msg;
  }

  // 列表时间格式：今年 MM-dd HH:mm，跨年带年份
  static timeText(seconds: number): string {
    const d = new Date(seconds * 1000);
    const pad = (n: number): string => n < 10 ? `0${n}` : `${n}`;
    const md = `${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
    return d.getFullYear() === new Date().getFullYear() ? md : `${d.getFullYear()}-${md}`;
  }
}
