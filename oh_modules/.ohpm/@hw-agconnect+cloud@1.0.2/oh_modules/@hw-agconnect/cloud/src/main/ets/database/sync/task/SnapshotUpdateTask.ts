/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { QuerySubscribePushResponse, SyncResult } from '../request/SyncResult';
import { ObjectWrapper } from '../ObjectWrapper';
import { naturalcloudsyncv2 } from '../../generated/syncmessage';
import { ErrorCode } from '../../utils/ErrorCode';

import OperationData = naturalcloudsyncv2.OperationData;
import SubscribePushMessage = naturalcloudsyncv2.SubscribePushMessage;
import Field = naturalcloudsyncv2.Field;

const TAG = 'SnapshotUpdateTask';

/**
 * SnapshotUpdateTask
 *
 * Server push subscribe data
 */
export class SnapshotUpdateTask {
  private readonly onPush: (ExceptionCode: ErrorCode, syncResult: SyncResult) => any;

  constructor(handle: (errorCode: ErrorCode, syncResult: SyncResult) => any) {
    this.onPush = handle;
  }

  onResponse(response: any, result: SyncResult) {
    const opData: OperationData[] = response.opData;
    const schemas = response.schemas;
    const tableName = schemas ? schemas[0]?.n : undefined;
    const pushMessage: any[] = [];
    const subPushMsg: SubscribePushMessage = response.subPushMsg;
    const resp: QuerySubscribePushResponse = {
      pushSeq: subPushMsg.pushSeq.toNumber(),
      storeName: response.msgInfo.opStore.storeName,
      subKey: subPushMsg.subKey,
      subRecId: subPushMsg.subRecId,
      subscribeId: subPushMsg.subId,
      responseObject: pushMessage,
      tableName,
      operationType: opData?.length > 0 ? opData[0]?.t : undefined
    };
    opData.forEach(op => {
      op.os.forEach(obj => {
        const fields = obj.fs as Field[];
        pushMessage.push(new ObjectWrapper(schemas[0], fields, op.t));
      });
    });
    const length = pushMessage.length;
    Logger.info(TAG, `[onResponse] enter, responseObjects size:${length ? length : 0}`);
    result.response = resp;
    this.onPush(result.responseCode, result);
  }
}
