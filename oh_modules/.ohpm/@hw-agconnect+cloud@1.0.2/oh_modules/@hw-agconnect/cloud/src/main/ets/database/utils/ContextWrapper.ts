/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { SyncMessageType } from '../sync/utils/EntityTemplate';
import { MessageType } from '../sync/ProtoHelper';

export const enum ApplicationType {
  OH = 'OpenHarmony'
}

const TAG = 'ContextWrapper';

export class ContextWrapper {
  static appVersion = '1.1.1';

  static getApplicationType() {
    return ApplicationType.OH;
  }

  static getApplicationVersion() {
    return ContextWrapper.appVersion;
  }

  static getWSocketMessageType(data: any): SyncMessageType {
    if (Object.prototype.hasOwnProperty.call(data, 'msgInfo')) {
      Logger.info(
        TAG,
        `getWSocketMessageType responseType: ${data.msgInfo?.type} errorCode: ${data.resInfo?.resCode}`
      );
      switch (data.msgInfo?.type) {
        case MessageType.QUERY_SUB:
          return SyncMessageType.SubscribeResponse;
        case MessageType.QUERY_SUB_PUSH:
          return SyncMessageType.SnapshotUpdate;
        case MessageType.QUERY_UNSUB:
          return SyncMessageType.UnsubscribeResponse;
        case MessageType.ENCRYPTION_TASK:
          return SyncMessageType.EncryptionResponse;
        default:
          Logger.warn(TAG, `unknown WSocket message type ${data.msgInfo?.type}`);
          break;
      }
    }
    return SyncMessageType.ErrorMessage;
  }
}
