import { StateStore } from '@hadss/state_store';
import type { Action } from '@hadss/state_store';
import { ServerInfo } from '../model/ServerInfo';
import { CryptoConfig } from '../model/CryptoConfig';
import type { PersistedState } from './AppPersistence';

// 所有状态变更都走这里 dispatch。工厂函数负责绑定 payload。
export class AppActionType {
  static readonly HYDRATE: string = 'hydrate';
  static readonly SET_FIRST_START: string = 'setFirstStart';
  static readonly SET_PUSH_TOKEN: string = 'setPushToken';
  static readonly SET_DEVICE_ID: string = 'setDeviceId';
  static readonly TOGGLE_SHOW_GROUP: string = 'toggleShowGroup';
  static readonly SET_DEFAULT_SOUND: string = 'setDefaultSound';
  static readonly SET_AUTO_SEND: string = 'setAutoSend';
  static readonly SET_QUICK_SEND: string = 'setQuickSend';
  static readonly SET_HAPTICS: string = 'setHaptics';
  static readonly SET_LAN_SHARE: string = 'setLanShare';
  static readonly SET_LAN_CODE: string = 'setLanCode';
  static readonly SET_HUAWEI_CREDENTIAL: string = 'setHuaweiCredential';
  static readonly CLEAR_HUAWEI_CREDENTIAL: string = 'clearHuaweiCredential';
  static readonly SET_QUICK_OPTIONS: string = 'setQuickOptions';
  static readonly SET_QUICK_DEFAULT: string = 'setQuickDefault';
  static readonly ADD_SERVER: string = 'addServer';
  static readonly REMOVE_SERVER: string = 'removeServer';
  static readonly REORDER_SERVER: string = 'reorderServer';
  static readonly SET_SERVER_KEY: string = 'setServerKey';
  static readonly SET_SERVER_STATUS: string = 'setServerStatus';
  static readonly ADD_QUICK_SERVER: string = 'addQuickServer';
  static readonly REMOVE_QUICK_SERVER: string = 'removeQuickServer';
  static readonly ADD_CRYPTO_CONFIG: string = 'addCryptoConfig';
  static readonly UPDATE_CRYPTO_CONFIG: string = 'updateCryptoConfig';
  static readonly REMOVE_CRYPTO_CONFIG: string = 'removeCryptoConfig';
  static readonly REORDER_CRYPTO_CONFIG: string = 'reorderCryptoConfig';
  static readonly SYNC_BUILTIN_CRYPTO: string = 'syncBuiltinCrypto';
}

export class AppActions {
  static hydrate(data: PersistedState): Action {
    return StateStore.createAction(AppActionType.HYDRATE, data);
  }

  static setFirstStart(value: boolean): Action {
    return StateStore.createAction(AppActionType.SET_FIRST_START, value);
  }

  static setPushToken(token: string): Action {
    return StateStore.createAction(AppActionType.SET_PUSH_TOKEN, token);
  }

  static setDeviceId(id: string): Action {
    return StateStore.createAction(AppActionType.SET_DEVICE_ID, id);
  }

  static toggleShowGroup(): Action {
    return StateStore.createAction(AppActionType.TOGGLE_SHOW_GROUP);
  }

  static setDefaultSound(name: string): Action {
    return StateStore.createAction(AppActionType.SET_DEFAULT_SOUND, name);
  }

  static setAutoSend(value: boolean): Action {
    return StateStore.createAction(AppActionType.SET_AUTO_SEND, value);
  }

  static setQuickSend(value: boolean): Action {
    return StateStore.createAction(AppActionType.SET_QUICK_SEND, value);
  }

  static setHaptics(value: boolean): Action {
    return StateStore.createAction(AppActionType.SET_HAPTICS, value);
  }

  static setLanShare(value: boolean): Action {
    return StateStore.createAction(AppActionType.SET_LAN_SHARE, value);
  }

  static setLanCode(code: string): Action {
    return StateStore.createAction(AppActionType.SET_LAN_CODE, code);
  }

  /// 保存华为账号登录凭证（unionID / openID）
  static setHuaweiCredential(unionID: string, openID: string): Action {
    const payload: HuaweiCredentialPayload = { unionID, openID };
    return StateStore.createAction(AppActionType.SET_HUAWEI_CREDENTIAL, payload);
  }

  /// 退出登录：清除本地华为账号凭证
  static clearHuaweiCredential(): Action {
    return StateStore.createAction(AppActionType.CLEAR_HUAWEI_CREDENTIAL);
  }

  // 快捷发送可选参数（标题/图标/提示音/来电时长）
  static setQuickOptions(payload: QuickOptionsPayload): Action {
    return StateStore.createAction(AppActionType.SET_QUICK_OPTIONS, payload);
  }

  // 设为快捷页默认服务器（其余 quickServers 取消默认标记）
  static setQuickDefault(id: string): Action {
    return StateStore.createAction(AppActionType.SET_QUICK_DEFAULT, id);
  }

  static addServer(server: ServerInfo): Action {
    return StateStore.createAction(AppActionType.ADD_SERVER, server);
  }

  static removeServer(id: string): Action {
    return StateStore.createAction(AppActionType.REMOVE_SERVER, id);
  }

  // 服务器列表内拖动排序（数组下标，按先移除后插入的 onItemMove 语义）
  static reorderServer(from: number, to: number): Action {
    const payload: ReorderPayload = { from, to };
    return StateStore.createAction(AppActionType.REORDER_SERVER, payload);
  }

  static setServerKey(id: string, key: string): Action {
    const payload: ServerKeyPayload = { id, key };
    return StateStore.createAction(AppActionType.SET_SERVER_KEY, payload);
  }

  static setServerStatus(id: string, status: number): Action {
    const payload: ServerStatusPayload = { id, status };
    return StateStore.createAction(AppActionType.SET_SERVER_STATUS, payload);
  }

  static addQuickServer(server: ServerInfo): Action {
    return StateStore.createAction(AppActionType.ADD_QUICK_SERVER, server);
  }

  static removeQuickServer(id: string): Action {
    return StateStore.createAction(AppActionType.REMOVE_QUICK_SERVER, id);
  }

  static addCryptoConfig(config: CryptoConfig): Action {
    return StateStore.createAction(AppActionType.ADD_CRYPTO_CONFIG, config);
  }

  static updateCryptoConfig(payload: CryptoConfigPayload): Action {
    return StateStore.createAction(AppActionType.UPDATE_CRYPTO_CONFIG, payload);
  }

  static removeCryptoConfig(id: string): Action {
    return StateStore.createAction(AppActionType.REMOVE_CRYPTO_CONFIG, id);
  }

  // 加密配置拖动排序（仅用户配置之间，系统内置固定首位，下标为数组全局下标）
  static reorderCryptoConfig(from: number, to: number): Action {
    const payload: ReorderPayload = { from, to };
    return StateStore.createAction(AppActionType.REORDER_CRYPTO_CONFIG, payload);
  }

  // 系统内置配置校正：启动时把内置项刷成与 iOS 一致的默认 key/iv（无 payload）
  static syncBuiltinCryptoConfig(): Action {
    return StateStore.createAction(AppActionType.SYNC_BUILTIN_CRYPTO, '');
  }
}

export interface ServerKeyPayload {
  id: string;
  key: string;
}

export interface ServerStatusPayload {
  id: string;
  status: number;
}

export interface ReorderPayload {
  from: number;
  to: number;
}

export interface CryptoConfigPayload {
  id: string;
  algorithm: number;
  mode: string;
  key: string;
  iv: string;
}

export interface QuickOptionsPayload {
  title: string;
  icon: string;
  sound: string;
  group: string;
}

export interface HuaweiCredentialPayload {
  unionID: string;
  openID: string;
}
