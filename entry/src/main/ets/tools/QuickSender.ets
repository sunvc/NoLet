import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ServerInfo } from '../model/ServerInfo';
import { noletUserAgent } from './UserAgent';
import { appStore } from '../store/AppStore';

// 快捷发送参数：title 必带（用户配置优先，否则用默认通知标题），icon/sound/group 有值才带
// （group 留空时不带，由服务端归入默认组）
export interface QuickSendOptions {
  title: string;
  icon?: string;
  sound?: string;
  group?: string;
}

// 从全局配置构造发送参数：侧边栏配置项为空则省略，title 留空时回退默认通知标题
export function buildQuickSendOptions(defaultTitle: string): QuickSendOptions {
  const state = appStore.getState();
  const options: QuickSendOptions = { title: state.quickTitle.trim() || defaultTitle };
  const icon: string = state.quickIcon.trim();
  const sound: string = state.quickSound.trim();
  const group: string = state.quickGroup.trim();
  if (icon) options.icon = icon;
  if (sound) options.sound = sound;
  if (group) options.group = group;
  return options;
}

// 快捷发送统一出口：GET {url}/{key}?title=…&body=<内容>&copy=body[&group=…]
// 可选参数 icon/sound/group 有值时追加。页面点击与进应用自动/确认发送共用。成功返回 true。
export async function sendQuickPush(server: ServerInfo, body: string, options: QuickSendOptions): Promise<boolean> {
  if (!server.url || !server.key || !body || !options.title) return false;
  let query: string = `title=${encodeURIComponent(options.title)}` +
    `&body=${encodeURIComponent(body)}&copy=body`;
  if (options.group) {
    query += `&group=${encodeURIComponent(options.group)}`;
  }
  if (options.icon) {
    query += `&icon=${encodeURIComponent(options.icon)}`;
  }
  if (options.sound) {
    query += `&sound=${encodeURIComponent(options.sound)}`;
  }
  const req = http.createHttp();
  try {
    const resp = await req.request(`${server.url}/${encodeURIComponent(server.key)}?${query}`, {
      method: http.RequestMethod.GET,
      header: { 'User-Agent': noletUserAgent() },
      connectTimeout: 10000,
      readTimeout: 10000,
      usingProtocol: http.HttpProtocol.HTTP1_1,
    });
    return resp.responseCode >= 200 && resp.responseCode < 300;
  } catch (e) {
    const err = e as BusinessError;
    console.error(`QuickSender failed: ${err.code} ${err.message}`);
    return false;
  } finally {
    req.destroy();
  }
}
