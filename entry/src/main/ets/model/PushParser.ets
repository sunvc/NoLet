import { util } from '@kit.ArkTS';
import { Message } from './Message';
import { PendingAction } from './PendingStore';

type Json = Record<string, Object>;

export interface ParseResult {
  action: PendingAction;
  message: Message;
  // 自定义铃声名（如 birdsong），仅通知到达时播放，不入库。
  // RemoteNotificationExtAbility 场景下铃声只能从 extraData 的 JSON 字符串中取；
  // 兼容 iOS 的 aps.sound（字符串或 {name} 字典）和顶层 sound。
  sound: string;
  // 角标绝对值（对应 iOS aps.badge / ?badge=n），≤0 清除；不传由系统/主应用维护
  badge?: number;
  // copy 参数原始值：'body' / 'title' 为占位符，其他原样；空表示不写剪贴板
  copy?: string;
}

// 加密推送：ciphertext 为 base64 密文，index 为密钥列表下标（缺省由调用方决定）
export interface CipherPayload {
  text: string;
  index?: number;
}

// 把推送 data JSON 解析成归档消息（字段与 iOS MessageItem 对齐）。
// title/body 优先取 aps.alert；ttl 为相对秒（>0 转绝对过期戳，-1 永久，0 不归档）。

function asDict(value: Object | undefined): Json | null {
  if (value !== undefined && value !== null && typeof value === 'object') {
    return value as Json;
  }
  return null;
}

function str(dict: Json, key: string): string {
  const value = dict[key];
  if (typeof value === 'string') return value as string;
  if (typeof value === 'number' || typeof value === 'boolean') return `${value}`;
  return '';
}

function num(dict: Json, key: string): number | undefined {
  const value = dict[key];
  if (typeof value === 'number') return value as number;
  if (typeof value === 'string') {
    const n = Number.parseInt(value as string, 10);
    return Number.isNaN(n) ? undefined : n;
  }
  return undefined;
}

function bool(dict: Json, key: string): boolean | undefined {
  const value = dict[key];
  if (typeof value === 'boolean') return value as boolean;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') return value === '1' || value === 'true';
  return undefined;
}

// title/body 读 aps.alert，sound 读 aps.sound（iOS 兼容），其余读顶层
function raw(dict: Json, key: string): string {
  if (key === 'title' || key === 'body') {
    const aps = asDict(dict['aps']);
    const alert = aps ? asDict(aps['alert']) : null;
    if (alert) {
      const v = str(alert, key);
      if (v) return v;
    }
  }
  return str(dict, key);
}

// 铃声查找顺序：extraData.sound → aps.sound → 顶层 sound；
// aps.sound 可能是字符串或 { name: 'xxx' }
function soundOf(dict: Json): string {
  const aps = asDict(dict['aps']);
  const fromAps = aps ? aps['sound'] : undefined;
  const v = fromAps !== undefined ? fromAps : dict['sound'];
  if (typeof v === 'string') return v as string;
  if (v !== undefined && v !== null && typeof v === 'object') {
    return str(v as Json, 'name');
  }
  return '';
}

// 华为推送自定义键值对放在 extraData 里（本身是 JSON 字符串，需二次 parse）；
// 个别模板直接给对象，两种都兼容
function parseExtra(dict: Json): Json | null {
  const raw = dict['data'];
  if (raw === undefined || raw === null) return null;
  if (typeof raw === 'string') {
    const s = (raw as string).trim();
    if (!s) return null;
    try {
      const parsed: Object = JSON.parse(s);
      return asDict(parsed);
    } catch {
      return null;
    }
  }
  return asDict(raw);
}

// 忽略大小写取值（服务端模板可能传 cipherText / cipherNumber 驼峰）
function ciValue(dict: Json, lowerKey: string): Object | undefined {
  const keys = Object.keys(dict);
  for (let i = 0; i < keys.length; i++) {
    if (keys[i].toLowerCase() === lowerKey) return dict[keys[i]];
  }
  return undefined;
}

function ciStr(dict: Json, lowerKey: string): string {
  const v = ciValue(dict, lowerKey);
  if (typeof v === 'string') return v as string;
  if (typeof v === 'number' || typeof v === 'boolean') return `${v}`;
  return '';
}

function ciNum(dict: Json, lowerKey: string): number | undefined {
  const v = ciValue(dict, lowerKey);
  if (typeof v === 'number') return v as number;
  if (typeof v === 'string') {
    const n = Number.parseInt(v as string, 10);
    return Number.isNaN(n) ? undefined : n;
  }
  return undefined;
}

// 提取加密推送字段：ciphertext 非空才算加密消息；ciphernumber 可选
export function extractCipher(dict: Json): CipherPayload | null {
  const text: string = ciStr(dict, 'ciphertext');
  if (!text) return null;
  const payload: CipherPayload = { text };
  const index = ciNum(dict, 'ciphernumber');
  if (index !== undefined) payload.index = index;
  return payload;
}

// 解析推送 JSON 并合并 extraData，供解密预处理与 parsePush 复用
export function parseMergedDict(data: string): Json | null {
  let dict: Json;
  try {
    dict = JSON.parse(data) as Json;
  } catch {
    return null;
  }
  if (!dict || typeof dict !== 'object') return null;

  // 华为推送的自定义键值对整体在 extraData（JSON 字符串）中；
  // extraData 内字段优先，顶层作为回退（兼容平铺模板与 iOS 结构）
  const extra = parseExtra(dict);
  const merged: Json = {};
  const mergeFrom = (src: Json): void => {
    const keys = Object.keys(src);
    for (let i = 0; i < keys.length; i++) {
      merged[keys[i]] = src[keys[i]];
    }
  };
  mergeFrom(dict);
  if (extra) mergeFrom(extra);
  return merged;
}

// fallbackGroup：推送未带 group 时的默认分组名，由调用方按当前语言传入
export function parsePush(data: string, fallbackGroup: string): ParseResult | null {
  const merged = parseMergedDict(data);
  if (!merged) return null;

  const id = str(merged, 'id') || util.generateRandomUUID(false);
  const title = raw(merged, 'title');
  // markdown 字段（iOS style=markdown）作为正文兜底；UI 侧统一按 Markdown 渲染
  const body = raw(merged, 'body') || str(merged, 'markdown');
  const url = str(merged, 'url');
  const group = str(merged, 'group') || fallbackGroup;

  // 只带 id 且无任何内容：删除对应消息
  if (!title && !body) {
    return { action: 'delete', message: new Message({ id }), sound: '' };
  }

  // ttl：相对秒转绝对过期戳；缺省永久；0 表示不归档
  const now = Math.floor(Date.now() / 1000);
  let ttl = -1;
  const rawTtl = num(merged, 'ttl');
  if (rawTtl !== undefined) {
    if (rawTtl < 0) ttl = -1;
    else if (rawTtl === 0) return null;
    else ttl = now + rawTtl;
  }

  const msg = new Message({
    id,
    createDate: now,
    group,
    title,
    body,
    url,
    icon: str(merged, 'icon'),
    image: str(merged, 'image'),
    ttl,
  });
  const read = bool(merged, 'read');
  if (read !== undefined) msg.read = read;

  const result: ParseResult = { action: 'upsert', message: msg, sound: soundOf(merged) };
  const badge = ciNum(merged, 'badge');
  if (badge !== undefined) result.badge = badge;
  const copy = str(merged, 'copy');
  if (copy) result.copy = copy;
  return result;
}
