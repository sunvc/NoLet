import type { Action, Reducer } from '@hadss/state_store';
import { AppStoreModel } from '../model/AppStoreModel';
import { ServerInfo } from '../model/ServerInfo';
import { CryptoConfig, CryptoAlgorithm, CryptoMode, DEFAULT_KEY, DEFAULT_IV } from '../model/CryptoConfig';
import { AppActionType } from './AppActions';
import type { ServerKeyPayload, ServerStatusPayload, ReorderPayload, CryptoConfigPayload, QuickOptionsPayload, HuaweiCredentialPayload } from './AppActions';
import type { PersistedState } from './AppPersistence';
import { restoreServers, restoreQuickServers, restoreCryptoConfigs } from './AppPersistence';

export const appReducer: Reducer<AppStoreModel> = (state: AppStoreModel, action: Action) => {
  switch (action.type) {
    case AppActionType.HYDRATE: {
      const data = action.payload as PersistedState;
      state.firstStart = data.firstStart;
      state.showGroup = data.showGroup;
      state.defaultSound = data.defaultSound;
      state.pushToken = data.pushToken;
      state.deviceId = data.deviceId;
      state.servers = restoreServers(data);
      state.quickServers = restoreQuickServers(data);
      state.autoSend = data.autoSend ?? false;
      state.quickSend = data.quickSend ?? false;
      state.haptics = data.haptics ?? true;
      state.lanShare = data.lanShare ?? false;
      state.lanCode = data.lanCode ?? '';
      state.huaweiUnionID = data.huaweiUnionID ?? '';
      state.huaweiOpenID = data.huaweiOpenID ?? '';
      state.quickTitle = data.quickTitle ?? '';
      state.quickIcon = data.quickIcon ?? '';
      state.quickSound = data.quickSound ?? '';
      state.quickGroup = data.quickGroup ?? '快捷消息';
      state.cryptoConfigs = restoreCryptoConfigs(data);
      return null;
    }
    case AppActionType.SET_FIRST_START:
      state.firstStart = action.payload as boolean;
      return null;
    case AppActionType.SET_PUSH_TOKEN:
      state.pushToken = action.payload as string;
      return null;
    case AppActionType.SET_DEVICE_ID:
      state.deviceId = action.payload as string;
      return null;
    case AppActionType.TOGGLE_SHOW_GROUP:
      state.showGroup = !state.showGroup;
      return null;
    case AppActionType.SET_DEFAULT_SOUND:
      state.defaultSound = action.payload as string;
      return null;
    case AppActionType.SET_AUTO_SEND:
      state.autoSend = action.payload as boolean;
      // 自动发送与询问发送互斥
      if (state.autoSend) state.quickSend = false;
      return null;
    case AppActionType.SET_QUICK_SEND:
      state.quickSend = action.payload as boolean;
      if (state.quickSend) state.autoSend = false;
      return null;
    case AppActionType.SET_HAPTICS:
      state.haptics = action.payload as boolean;
      return null;
    case AppActionType.SET_LAN_SHARE:
      state.lanShare = action.payload as boolean;
      return null;
    case AppActionType.SET_LAN_CODE:
      state.lanCode = action.payload as string;
      return null;
    case AppActionType.SET_HUAWEI_CREDENTIAL: {
      const payload = action.payload as HuaweiCredentialPayload;
      state.huaweiUnionID = payload.unionID;
      state.huaweiOpenID = payload.openID;
      return null;
    }
    case AppActionType.CLEAR_HUAWEI_CREDENTIAL:
      state.huaweiUnionID = '';
      state.huaweiOpenID = '';
      return null;
    case AppActionType.SET_QUICK_OPTIONS: {
      const payload = action.payload as QuickOptionsPayload;
      state.quickTitle = payload.title;
      state.quickIcon = payload.icon;
      state.quickSound = payload.sound;
      state.quickGroup = payload.group;
      return null;
    }
    case AppActionType.SET_QUICK_DEFAULT: {
      const id = action.payload as string;
      state.quickServers.forEach((s: ServerInfo): void => { s.isDefault = s.id === id; });
      return null;
    }
    case AppActionType.ADD_SERVER:
      state.servers.push(action.payload as ServerInfo);
      return null;
    case AppActionType.REMOVE_SERVER: {
      const id = action.payload as string;
      state.servers = state.servers.filter((s: ServerInfo): boolean => s.id !== id);
      return null;
    }
    case AppActionType.REORDER_SERVER: {
      const payload = action.payload as ReorderPayload;
      const arr: ServerInfo[] = state.servers;
      if (payload.from === payload.to ||
        payload.from < 0 || payload.to < 0 ||
        payload.from >= arr.length || payload.to >= arr.length) {
        return null;
      }
      const next: ServerInfo[] = arr.slice();
      const moved: ServerInfo = next.splice(payload.from, 1)[0];
      next.splice(payload.to, 0, moved);
      state.servers = next;
      return null;
    }
    case AppActionType.SET_SERVER_KEY: {
      const payload = action.payload as ServerKeyPayload;
      const target = state.servers.find((s: ServerInfo): boolean => s.id === payload.id);
      if (target) target.key = payload.key;
      return null;
    }
    case AppActionType.SET_SERVER_STATUS: {
      const payload = action.payload as ServerStatusPayload;
      const target = state.servers.find((s: ServerInfo): boolean => s.id === payload.id);
      if (target) target.status = payload.status;
      return null;
    }
    case AppActionType.ADD_QUICK_SERVER:
      state.quickServers.push(action.payload as ServerInfo);
      return null;
    case AppActionType.REMOVE_QUICK_SERVER: {
      const id = action.payload as string;
      state.quickServers = state.quickServers.filter((s: ServerInfo): boolean => s.id !== id);
      return null;
    }
    case AppActionType.ADD_CRYPTO_CONFIG:
      state.cryptoConfigs.push(action.payload as CryptoConfig);
      return null;
    case AppActionType.UPDATE_CRYPTO_CONFIG: {
      const payload = action.payload as CryptoConfigPayload;
      const target = state.cryptoConfigs.find((c: CryptoConfig): boolean => c.id === payload.id);
      // 系统内置保留项拒绝任何修改
      if (target && !target.builtin) {
        target.algorithm = payload.algorithm;
        target.mode = payload.mode;
        target.key = payload.key;
        target.iv = payload.iv;
      }
      return null;
    }
    case AppActionType.REMOVE_CRYPTO_CONFIG: {
      const id = action.payload as string;
      // 系统内置保留项不可删除
      state.cryptoConfigs = state.cryptoConfigs.filter(
        (c: CryptoConfig): boolean => c.id !== id || c.builtin);
      return null;
    }
    case AppActionType.SYNC_BUILTIN_CRYPTO: {
      // 系统同步而非用户编辑：把内置项强制刷成规范默认值（修早期示例 IV）
      const target = state.cryptoConfigs.find((c: CryptoConfig): boolean => c.builtin);
      if (target) {
        target.algorithm = CryptoAlgorithm.AES256;
        target.mode = CryptoMode.GCM;
        target.key = DEFAULT_KEY;
        target.iv = DEFAULT_IV;
      }
      return null;
    }
    case AppActionType.REORDER_CRYPTO_CONFIG: {
      const payload = action.payload as ReorderPayload;
      const arr: CryptoConfig[] = state.cryptoConfigs;
      // 系统内置项固定首位，任何移动不得触及下标 0
      if (payload.from === payload.to || payload.from < 1 || payload.to < 1 ||
        payload.from >= arr.length || payload.to >= arr.length ||
        arr[payload.from].builtin || arr[payload.to].builtin) {
        return null;
      }
      const next: CryptoConfig[] = arr.slice();
      const moved: CryptoConfig = next.splice(payload.from, 1)[0];
      next.splice(payload.to, 0, moved);
      state.cryptoConfigs = next;
      return null;
    }
    default:
      return null;
  }
};
