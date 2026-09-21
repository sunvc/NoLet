import { pasteboard } from '@kit.BasicServicesKit';
import { Message } from '../model/Message';

// 推送 copy 参数处理（扩展进程与前台接收共用）：
// 'body' → 正文实际内容，'title' → 标题实际内容，其他值原样；目标为空则跳过。
export function applyPushCopy(copy: string | undefined, msg: Message): void {
  if (!copy) return;
  const text: string = copy === 'body' ? msg.body : copy === 'title' ? msg.title : copy;
  if (!text) return;
  const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
  pasteboard.getSystemPasteboard().setData(data);
}
