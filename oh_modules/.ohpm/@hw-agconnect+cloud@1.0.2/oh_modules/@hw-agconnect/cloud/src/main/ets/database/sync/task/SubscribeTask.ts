/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { WebSocketTask } from './WebSocketTask';
import { SyncResult } from '../request/SyncResult';
import { ErrorCode } from '../../utils/ErrorCode';
import { naturalcloudsyncv2 } from '../../generated/syncmessage';
import { SyncRequest } from '../request/SyncRequest';
import { SyncRequestProcessor } from '../SyncRequestProcessor';

import SyncResponseMessage = naturalcloudsyncv2.SyncResponseMessage;

const TAG = 'SubscribeTask';

/**
 * SubscribeTask
 *
 * 1、subscribeForRekey
 * 2、onSubscribe
 */
export class SubscribeTask extends WebSocketTask {
  private onSubscribeResponse: (errorCode: ErrorCode, syncResult: SyncResult) => void;

  constructor(
    syncRequest: SyncRequest,
    keyVersion: number,
    handle: (errorCode: ErrorCode, syncResult: SyncResult) => any,
    syncProcessor: SyncRequestProcessor
  ) {
    super(syncRequest, handle, syncProcessor);
    this.syncRequest.encryptionVersion = keyVersion;
    this.onSubscribeResponse = handle;
  }

  onResponse(
    response: SyncResponseMessage,
    result: SyncResult,
    syncProcessor: SyncRequestProcessor
  ): void {
    const subscribeResults: any[] = [];
    response.subResMsg.forEach((message: naturalcloudsyncv2.ISubscribeResponseMessage) => {
      let subscribeResult: ErrorCode;
      if (response.resInfo?.resCode === ErrorCode.SYNC_THREAD_POOL_REJECTED) {
        subscribeResult = ErrorCode.SYNC_THREAD_POOL_REJECTED;
      } else {
        subscribeResult = message.subResCode as ErrorCode;
      }
      subscribeResults.push({
        cloudSubRecordId: message?.subRecId,
        subscribeId: message?.subId,
        subKey: message?.subKey,
        result: subscribeResult,
        subResponseCode: message.subResCode
      });
      if (message?.subRecId) {
        syncProcessor.getSubscribeRecordSet().add(message?.subRecId);
      }
    });
    result.response = {
      subscribeResults
    };
    if (syncProcessor.getSubscribeTaskIdSet().has(response.msgInfo!.id!.toString())) {
      Logger.info(
        TAG,
        `[onResponse] subscribeTaskIdSet size : ${syncProcessor.getSubscribeTaskIdSet().size}`
      );
      syncProcessor.getSubscribeTaskIdSet().delete(response.msgInfo!.id!.toString());
    }
    Logger.info(TAG, `[onResponse] subscribeResults size : ${subscribeResults.length}`);
    this.onSubscribeResponse?.call(null, ErrorCode.OK, result);
  }

  request(): void {
    Logger.info(
      TAG,
      `[request] taskId: ${this.syncRequest.taskId} \
            requestType: ${this.syncRequest.requestType}`
    );
    if (this.syncRequest.taskId) {
      this.syncProcessor?.getSubscribeTaskIdSet().add(this.syncRequest.taskId.toString());
    }
    Logger.info(
      TAG,
      `[request] subscribeRecordSet len: ${this.syncProcessor?.getSubscribeRecordSet().size}`
    );
    this.syncProcessor?.getWebSocketClient().sendSubscribeRequest(this.syncRequest);
  }
}
