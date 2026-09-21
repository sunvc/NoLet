import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Message, MessageItem } from './Message';

const DOMAIN = 0x0000;
const TAG = 'PendingStore';
const FILE_NAME = 'nolet_pending.jsonl';

// 待处理消息：upsert 归档，或 delete 按 id 删除（推送只带 id 即删消息）
export type PendingAction = 'upsert' | 'delete';

export interface PendingItem extends MessageItem {
  action: PendingAction;
}

// 对应 iOS PendingMessageStore：remoteNotification 扩展与主应用跨进程，
// 扩展把消息追加到沙盒 JSONL，主应用启动/回前台时 drain 入库。
function pendingPath(context: common.Context): string {
  return `${context.filesDir}/${FILE_NAME}`;
}

function pendingAppend(context: common.Context, item: PendingItem): void {
  try {
    const fd = fs.openSync(pendingPath(context),
      fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND);
    fs.writeSync(fd.fd, JSON.stringify(item) + '\n');
    fs.closeSync(fd);
  } catch (e) {
    hilog.error(DOMAIN, TAG, `append failed: ${(e as Error).message}`);
  }
}

export function pendingAppendUpsert(context: common.Context, msg: Message): void {
  const item: PendingItem = {
    action: 'upsert',
    id: msg.id,
    group: msg.group,
    createDate: msg.createDate,
    title: msg.title,
    body: msg.body,
    icon: msg.icon,
    url: msg.url,
    image: msg.image,
    ttl: msg.ttl,
    read: msg.read,
  };
  pendingAppend(context, item);
}

export function pendingAppendDelete(context: common.Context, id: string): void {
  const item: PendingItem = { action: 'delete', id };
  pendingAppend(context, item);
}

export async function pendingDrain(context: common.Context): Promise<PendingItem[]> {
  const file = pendingPath(context);
  try {
    if (!fs.accessSync(file)) return [];
    const text = fs.readTextSync(file);
    fs.unlinkSync(file);
    const items: PendingItem[] = [];
    const lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const trimmed = lines[i].trim();
      if (!trimmed) continue;
      try {
        items.push(JSON.parse(trimmed) as PendingItem);
      } catch {
        // 跳过损坏行
      }
    }
    return items;
  } catch (e) {
    hilog.error(DOMAIN, TAG, `drain failed: ${(e as Error).message}`);
    return [];
  }
}
