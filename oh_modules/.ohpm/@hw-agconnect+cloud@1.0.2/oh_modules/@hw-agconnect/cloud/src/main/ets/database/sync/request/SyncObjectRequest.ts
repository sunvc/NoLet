/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { SyncRequest } from './SyncRequest';
import { MessageType, OperationType } from '../utils/MessageType';

export class SyncObjectRequest extends SyncRequest {
  constructor() {
    super();
    this.requestType = MessageType.OBJECT_UPDATE;
  }

  private operationType_: OperationType | undefined;
  private objectList_: any[] = [];

  get objList(): any[] {
    return this.objectList_;
  }

  set objList(sourceObjectList: any[]) {
    this.objectList_ = sourceObjectList;
  }

  get operationType(): OperationType | undefined {
    return this.operationType_;
  }

  set operationType(sourceObjectList: OperationType | undefined) {
    this.operationType_ = sourceObjectList;
  }
}
