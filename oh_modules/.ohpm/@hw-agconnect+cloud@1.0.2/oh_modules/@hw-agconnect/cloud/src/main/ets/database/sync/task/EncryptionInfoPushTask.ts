/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { SyncRequestProcessor } from '../SyncRequestProcessor';
import { ErrorCode } from '../../utils/ErrorCode';

const TAG = 'EncryptionInfoPushTask';

export class EncryptionInfoPushTask {
  onResponse(response: any, result: any, syncProcessor?: SyncRequestProcessor): void {
    const encryptPushMessage = response.msgInfo;
    if (!encryptPushMessage) {
      Logger.error(TAG, `[onResponse] invalid encryptionResponseMessage!`);
      return;
    }
    const messageType = encryptPushMessage.subType;
    const encryptionInfoList = response.enResInfo;
    const length = encryptionInfoList?.length;
    Logger.info(TAG, `[onResponse] messageType: ${messageType} encryptionInfoList size:${length}`);
    result.response = {
      encryptionInfoList: response.enResInfo,
      encryptionMessageType: messageType
    };
    syncProcessor?.getEncryptionInfoPush()?.call(null, ErrorCode.OK, result);
  }
}
