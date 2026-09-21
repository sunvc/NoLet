import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppStoreModel } from '../model/AppStoreModel';
import { ServerInfo } from '../model/ServerInfo';
import { CryptoConfig, CryptoAlgorithm, CryptoMode, DEFAULT_KEY, DEFAULT_IV } from '../model/CryptoConfig';

// Preferences 显式持久化：StateStore 只管内存状态，落盘在这里做。
// 只持久化配置本身（id/url/key），status 是瞬时探测结果不入库。

const STORE_NAME: string = 'app_state';
const KEY_STATE: string = 'state';

export interface PersistedServer {
  id: string;
  url: string;
  key: string;
  group?: string;
  remark?: string;
  isDefault?: boolean;
}

export interface PersistedCryptoConfig {
  id: string;
  algorithm: number;
  mode: string;
  key: string;
  iv: string;
  builtin?: boolean;
}

export interface PersistedState {
  firstStart: boolean;
  showGroup: boolean;
  defaultSound: string;
  pushToken: string;
  deviceId: string;
  autoSend?: boolean;
  quickSend?: boolean;
  // 旧版本数据缺省时按开启处理
  haptics?: boolean;
  // 局域网共享开关与接收码，旧版本缺省关闭/空
  lanShare?: boolean;
  lanCode?: string;
  // 华为账号凭证，旧版本缺省为空
  huaweiUnionID?: string;
  huaweiOpenID?: string;
  // 快捷发送可选参数，旧版本缺省为空
  quickTitle?: string;
  quickIcon?: string;
  quickSound?: string;
  // 旧版本缺省按「快捷消息」处理
  quickGroup?: string;
  servers: PersistedServer[];
  // 快捷页发送目标（非本机），旧版本数据缺省为空数组
  quickServers?: PersistedServer[];
  cryptoConfigs?: PersistedCryptoConfig[];
}

let prefs: preferences.Preferences | null = null;

export async function initAppPrefs(context: common.Context): Promise<void> {
  prefs = await preferences.getPreferences(context, STORE_NAME);
}

export function readPersistedState(): PersistedState | null {
  if (prefs === null) return null;
  const raw: string = prefs.getSync(KEY_STATE, '') as string;
  if (!raw) return null;
  try {
    return JSON.parse(raw) as PersistedState;
  } catch {
    return null;
  }
}

// 推送扩展进程未初始化单例 prefs，用自己的 context 直接打开同一 Preferences 文件
export async function readCryptoConfigsForContext(context: common.Context): Promise<CryptoConfig[]> {
  try {
    const store = await preferences.getPreferences(context, STORE_NAME);
    const raw: string = store.getSync(KEY_STATE, '') as string;
    if (!raw) return [];
    return restoreCryptoConfigs(JSON.parse(raw) as PersistedState);
  } catch {
    return [];
  }
}

export async function writePersistedState(state: AppStoreModel): Promise<void> {
  if (prefs === null) return;
  const servers: PersistedServer[] = state.servers.map((s: ServerInfo): PersistedServer => {
    const item: PersistedServer = { id: s.id, url: s.url, key: s.key };
    if (s.group) item.group = s.group;
    return item;
  });
  const quickServers: PersistedServer[] = state.quickServers.map((s: ServerInfo): PersistedServer => {
    const item: PersistedServer = { id: s.id, url: s.url, key: s.key };
    if (s.remark) item.remark = s.remark;
    if (s.isDefault) item.isDefault = true;
    return item;
  });
  const cryptoConfigs: PersistedCryptoConfig[] =
    state.cryptoConfigs.map((c: CryptoConfig): PersistedCryptoConfig => {
      const item: PersistedCryptoConfig = { id: c.id, algorithm: c.algorithm, mode: c.mode, key: c.key, iv: c.iv };
      if (c.builtin) item.builtin = true;
      return item;
    });
  const data: PersistedState = {
    firstStart: state.firstStart,
    showGroup: state.showGroup,
    defaultSound: state.defaultSound,
    pushToken: state.pushToken,
    deviceId: state.deviceId,
    autoSend: state.autoSend,
    quickSend: state.quickSend,
    haptics: state.haptics,
    lanShare: state.lanShare,
    lanCode: state.lanCode,
    huaweiUnionID: state.huaweiUnionID,
    huaweiOpenID: state.huaweiOpenID,
    quickTitle: state.quickTitle,
    quickIcon: state.quickIcon,
    quickSound: state.quickSound,
    quickGroup: state.quickGroup,
    servers,
    quickServers,
    cryptoConfigs,
  };
  await prefs.put(KEY_STATE, JSON.stringify(data));
  await prefs.flush();
}

// Preferences 读出的是普通对象，构造回可观察的 ServerInfo 实例
export function restoreServers(data: PersistedState | null): ServerInfo[] {
  const result: ServerInfo[] = [];
  if (data !== null) {
    data.servers.forEach((p: PersistedServer): void => {
      const s: ServerInfo = new ServerInfo();
      s.id = p.id;
      s.url = p.url;
      s.key = p.key;
      s.group = p.group ?? '';
      result.push(s);
    });
  }
  return result;
}

// 快捷页发送目标列表（非本机服务器）
export function restoreQuickServers(data: PersistedState | null): ServerInfo[] {
  const result: ServerInfo[] = [];
  if (data !== null && data.quickServers) {
    data.quickServers.forEach((p: PersistedServer): void => {
      const s: ServerInfo = new ServerInfo();
      s.id = p.id;
      s.url = p.url;
      s.key = p.key;
      s.remark = p.remark ?? '';
      s.isDefault = p.isDefault ?? false;
      result.push(s);
    });
  }
  return result;
}

// 构造回 CryptoConfig 实例
export function restoreCryptoConfigs(data: PersistedState | null): CryptoConfig[] {
  const result: CryptoConfig[] = [];
  if (data !== null && data.cryptoConfigs) {
    data.cryptoConfigs.forEach((p: PersistedCryptoConfig): void => {
      const c = new CryptoConfig();
      c.id = p.id;
      c.algorithm = p.algorithm;
      c.mode = p.mode;
      c.key = p.key;
      c.iv = p.iv;
      // 老版本落盘数据无 builtin 字段：按固定默认参数识别系统保留项（仅首个匹配）
      if (p.builtin !== undefined) {
        c.builtin = p.builtin;
      } else {
        c.builtin = c.algorithm === CryptoAlgorithm.AES256 && c.mode === CryptoMode.GCM
          && c.key === DEFAULT_KEY && c.iv === DEFAULT_IV
          && !result.some((x: CryptoConfig): boolean => x.builtin);
      }
      result.push(c);
    });
  }
  return result;
}
