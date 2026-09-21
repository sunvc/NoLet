import { url } from '@kit.ArkTS';

// 服务器深链（与 iOS 端统一）：nolet://server?text=<服务器地址>[&key=<KEY>]
// 旧版本使用 pb://server，识别时两种协议都兼容
export interface ServerLink {
  url: string;
  key: string;
}

// 内容是否为服务器深链（nolet:// 或旧版 pb://），解析失败时用于区分「无效链接」与「普通文本」
export function isPbLink(content: string): boolean {
  return /^(nolet|pb):\/\//i.test(content.trim());
}

// 解析服务器添加链接；非 nolet://pb://、host 不是 server 或缺少 text 时返回 null。
// text 值按 query 规则自动百分号解码，兼容是否编码两种情况。
export function parseServerLink(content: string): ServerLink | null {
  const raw: string = content.trim();
  if (!isPbLink(raw)) return null;
  try {
    const u: url.URL = new url.URL(raw);
    const proto: string = u.protocol.toLowerCase();
    if (proto !== 'nolet:' && proto !== 'pb:') {
      return null;
    }
    if (u.host.toLowerCase() !== 'server') {
      return null;
    }
    const server: string = u.params.get('text') ?? '';
    if (!server) return null;
    const link: ServerLink = {
      url: server,
      key: u.params.get('key') ?? ''
    };
    return link;
  } catch {
    return null;
  }
}

// 加密配置深链：nolet://crypto?text=<Domap 混淆配置串>
export function buildCryptoLink(obfuscated: string): string {
  return `nolet://crypto?text=${encodeURIComponent(obfuscated)}`;
}

// 解析加密配置链接，返回 text 中的 Domap 混淆串；非 nolet://crypto 或缺少 text 时返回 null。
// 裸混淆串不是链接，返回 null，由调用方直接 deobfuscate。
export function parseCryptoLink(content: string): string | null {
  const raw: string = content.trim();
  if (!isPbLink(raw)) return null;
  try {
    const u: url.URL = new url.URL(raw);
    if (u.protocol.toLowerCase() !== 'nolet:' || u.host.toLowerCase() !== 'crypto') {
      return null;
    }
    return u.params.get('text') ?? null;
  } catch {
    return null;
  }
}
