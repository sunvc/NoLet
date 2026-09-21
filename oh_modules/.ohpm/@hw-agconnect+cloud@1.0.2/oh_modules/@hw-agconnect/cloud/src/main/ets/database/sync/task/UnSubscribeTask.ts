/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { WebSocketTask } from './WebSocketTask';
import { ErrorCode } from '../../utils/ErrorCode';
import { SyncResult } from '../request/SyncResult';
import { naturalcloudsyncv2 } from '../../generated/syncmessage';
import { UnSubscribeRequest } from '../request/UnsubscribeRequest';
import { SyncRequest } from '../request/SyncRequest';
import { SyncRequestProcessor } from '../SyncRequestProcessor';

import SyncResponseMessage = naturalcloudsyncv2.SyncResponseMessage;

const TAG = 'UnSubscribeTask';

export class UnSubscribeTask extends WebSocketTask {
  private onUnSubscribeResponse: (errorCode: ErrorCode, syncResult: SyncResult) => void;

  constructor(
    syncRequest: SyncRequest,
    keyVersion: number,
    handle: (errorCode: ErrorCode, syncResult: SyncResult) => any,
    syncProcessor: SyncRequestProcessor
  ) {
    super(syncRequest, handle, syncProcessor);
    this.syncRequest.encryptionVersion = keyVersion;
    this.onUnSubscribeResponse = this.handle;
  }

  onResponse(
    response: SyncResponseMessage,
    result: SyncResult,
    syncProcessor: SyncRequestProcessor
  ): void {
    const unSubScribeResults: any[] = [];
    response.unSubResMsg?.forEach((message: naturalcloudsyncv2.IUnsubscribeResponseMessage) => {
      unSubScribeResults.push({
        cloudSubRecordId: message?.unSubRecId,
        ExceptionCode: message?.unSubResCode
      });
    });
    result.response = {
      unSubScribeResults
    };
    Logger.info(
      TAG,
      `[onResponse] unSubScribeResults size: ${unSubScribeResults.length} \
            subscribeRecordSet.size ${syncProcessor.getSubscribeRecordSet().size}`
    );
    this.onUnSubscribeResponse?.call(null, ErrorCode.OK, result);
    if (syncProcessor.needToDisconnectWebsocket()) {
      Logger.info(TAG, '[onResponse] stopHeartBeat since there is no subscriber.');
      syncProcessor.getWebSocketClient().stopHeartBeat();
    }
  }

  request(): void {
    Logger.info(
      TAG,
      `[request] taskId: ${this.syncRequest.taskId} \
            requestType:${this.syncRequest.requestType}`
    );
    for (const unsubscribeData of (this.syncRequest as UnSubscribeRequest).unSubscribeDatas) {
      this.syncProcessor?.getSubscribeRecordSet().delete(unsubscribeData.cloudSubRecordId);
    }
    Logger.info(
      TAG,
      `[request] subscribeRecordSet.size ${this.syncProcessor?.getSubscribeRecordSet().size}`
    );
    const unSubScribeResults: {
      cloudSubRecordId: string;
      errorCode: ErrorCode;
    }[] = [];
    this.syncProcessor?.getWebSocketClient().sendUnsubscribeRequest(this.syncRequest, () => {
      (this.syncRequest as UnSubscribeRequest).unSubscribeDatas.forEach(
        (data: { cloudSubRecordId: string }) => {
          unSubScribeResults.push({
            cloudSubRecordId: data.cloudSubRecordId,
            errorCode: ErrorCode.OK
          });
        }
      );

      const dummyUnsubscribeResult: any = {
        responseCode: ErrorCode.OK,
        responseType: this.syncRequest.requestType,
        taskId: this.syncRequest.taskId,
        storeName: this.syncRequest.naturalStoreName,
        response: { unSubScribeResults }
      };
      this.onUnSubscribeResponse.call(null, ErrorCode.OK, dummyUnsubscribeResult);
    });
  }
}
