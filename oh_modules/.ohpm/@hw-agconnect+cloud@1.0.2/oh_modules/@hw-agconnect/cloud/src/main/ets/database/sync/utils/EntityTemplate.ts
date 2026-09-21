/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
// @ts-ignore
import Long from 'long';

export const enum SyncMessageType {
  SubscribeResponse = 'SubscribeResponse',
  SnapshotUpdate = 'SnapshotUpdate',
  UnsubscribeRequest = 'UnsubscribeRequest',
  UnsubscribeResponse = 'UnsubscribeResponse',
  EncryptionResponse = 'EncryptionResponse',
  ErrorMessage = 'ErrorMessage',
  Unknown = 'unknown'
}

export const enum AgcMsgType {
  ONLINE_MSG = 'REGISTER',
  ONLINE_RESP_MSG = 'REGISTER_RSP',
  COMMON_MSG = 'COMMON_MSG',
  COMMON_MSG_RSP = 'COMMON_MSG_RSP',
  HEARTBEAT_MSG = 'HEARTBEAT',
  HEARTBEAT_RSP = 'HEARTBEAT_RSP',
  OFFLINE_MSG = 'UNREGISTER',
  SERVER_PUSH_MSG = 'NOTIFY_MSG',
  SERVER_PUSH_MSG_RSP = 'NOTIFY_MSG_RSP'
}

export const enum ContextType {
  JSON = 'application/json; charset=UTF-8',
  PROTO_BUF = 'application/octet-stream'
}

// message from cloud
export type SubscribeResponse = {
  resultCode: number;
  message: string;
  subscribeInfo: any[];
};

export type UnsubscribeRequest = {
  listenerId: number;
  taskId: Long;
};

export type UnsubscribeRequestMessage = {
  type: number;
  naturalStoreName: string;
  taskId: Long;
  productId: string;
  subscribeList: any[];
};
