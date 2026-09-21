/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { QueryType } from './SyncResult';
import { SyncRequest } from './SyncRequest';
import { MessageType } from '../utils/MessageType';

export class SyncQueryRequest extends SyncRequest {
  constructor() {
    super();
    this.requestType = MessageType.OBJECT_QUERY;
  }

  private tableName_!: string;

  private queryCondition_!: string;

  private queryType_!: QueryType;

  get tableName(): string {
    return this.tableName_;
  }

  set tableName(sourceTableName: string) {
    this.tableName_ = sourceTableName;
  }

  get queryCondition(): string {
    return this.queryCondition_;
  }

  set queryCondition(sourceQueryCondition: string) {
    this.queryCondition_ = sourceQueryCondition;
  }

  get queryType(): QueryType {
    return this.queryType_;
  }

  set queryType(sourceQueryType: QueryType) {
    this.queryType_ = sourceQueryType;
  }
}
