/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { SyncRequest } from './SyncRequest';
import { MessageType } from '../ProtoHelper';
import { OperationType } from '../utils/MessageType';
import { naturalcloudsyncv2 } from '../../generated/syncmessage';
import { ObjectWrapper } from '../ObjectWrapper';

import OperationData = naturalcloudsyncv2.OperationData;

export class TransactionRequest extends SyncRequest {
  constructor() {
    super();
    this.requestType = MessageType.TRANSACTION;
  }

  private verifyObjects_: ObjectWrapper[] = [];

  private transactionDatas_: TransactionData[] = [];

  get verifyObjects(): ObjectWrapper[] {
    return this.verifyObjects_;
  }

  set verifyObjects(sourceObjects: ObjectWrapper[]) {
    this.verifyObjects_ = sourceObjects;
  }

  get transactionDatas(): TransactionData[] {
    return this.transactionDatas_;
  }

  set transactionDatas(sourceDatas: TransactionData[]) {
    this.transactionDatas_ = sourceDatas;
  }
}

export type TransactionData = {
  operationType: OperationType;
  objectTypeName: string;
  objects: OperationData[];
};
