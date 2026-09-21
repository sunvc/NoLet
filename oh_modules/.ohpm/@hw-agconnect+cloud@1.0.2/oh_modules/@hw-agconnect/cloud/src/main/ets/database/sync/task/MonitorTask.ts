/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { WebSocketTask } from './WebSocketTask';
import { MessageSubType } from '../utils/MessageType';
import { ErrorCode } from '../../utils/ErrorCode';
import { SyncResult } from '../request/SyncResult';
import { EncryptRequest } from '../request/EncryptRequest';
import { SyncRequestProcessor } from '../SyncRequestProcessor';

const TAG = 'MonitorTask';

/**
 * 1、MONITOR_USER_COMMAND_CHANGE
 * 2、MONITOR_DATA_KEY_CHANGE
 */
export class MonitorTask extends WebSocketTask {
  private userCommandMonitorResponse:
    | ((ExceptionCode: ErrorCode, syncResult: SyncResult) => any)
    | undefined;

  private userKeyMonitorResponse:
    | ((ExceptionCode: ErrorCode, syncResult: SyncResult) => any)
    | undefined;

  constructor(
    syncRequest: EncryptRequest,
    keyVersion: number,
    handle: (errorCode: ErrorCode, syncResult: SyncResult) => any,
    syncProcessor: SyncRequestProcessor
  ) {
    super(syncRequest, handle, syncProcessor);
    this.syncRequest.encryptionVersion = keyVersion;
  }

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
    if (messageType === MessageSubType.MONITOR_USER_COMMAND_CHANGE) {
      this.userCommandMonitorResponse!(ErrorCode.OK, result);
    } else if (messageType === MessageSubType.MONITOR_DATA_KEY_CHANGE) {
      this.userKeyMonitorResponse!(ErrorCode.OK, result);
    }
  }

  request(): void {
    Logger.info(
      TAG,
      `MonitorTask taskId: ${this.syncRequest.taskId} \
            encryptType: ${this.syncRequest.requestSubType}`
    );
    if (this.syncRequest.requestSubType === MessageSubType.MONITOR_USER_COMMAND_CHANGE) {
      this.commandMonitor(this.syncRequest, this.handle);
    } else if (this.syncRequest.requestSubType === MessageSubType.MONITOR_DATA_KEY_CHANGE) {
      this.userKeyMonitor(this.syncRequest, this.handle);
    } else {
      Logger.warn(TAG, `MonitorTask taskId: ${this.syncRequest.taskId} is not need to call`);
    }
  }

  commandMonitor(syncRequest: any, callback: any): void {
    this.syncProcessor?.getWebSocketClient().subEncryption(syncRequest, () => {
      Logger.info(TAG, `commandMonitorTask: add user command changed monitor success!`);
    });
    this.userCommandMonitorResponse = callback;
  }

  userKeyMonitor(syncRequest: any, callback: any): void {
    this.syncProcessor?.getWebSocketClient().subEncryption(syncRequest, () => {
      Logger.info(TAG, `userKeyMonitorTask: add user key changed monitor success!`);
    });
    this.userKeyMonitorResponse = callback;
  }
}
