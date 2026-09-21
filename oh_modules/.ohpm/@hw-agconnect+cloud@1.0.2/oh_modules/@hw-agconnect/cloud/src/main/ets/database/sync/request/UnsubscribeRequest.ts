/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { SyncRequest } from './SyncRequest';
import { MessageType } from '../utils/MessageType';

export class UnSubscribeRequest extends SyncRequest {
  constructor() {
    super();
    this.requestType = MessageType.QUERY_UNSUB;
  }

  private unSubscribeDatas_: UnSubscribeData[] = [];

  get unSubscribeDatas(): UnSubscribeData[] {
    return this.unSubscribeDatas_;
  }

  set unSubscribeDatas(sourceSubscribeDatas: UnSubscribeData[]) {
    this.unSubscribeDatas_ = sourceSubscribeDatas;
  }
}

export class UnSubscribeData {
  private naturalStoreName_!: string;

  private tableName_!: string;

  private cloudSubRecordId_!: string;

  private cloudSubKey_!: number;

  private subscribeId_!: string;

  get naturalStoreName(): string {
    return this.naturalStoreName_;
  }

  set naturalStoreName(sourceStoreName: string) {
    this.naturalStoreName_ = sourceStoreName;
  }

  get tableName(): string {
    return this.tableName_;
  }

  set tableName(sourceTableName: string) {
    this.tableName_ = sourceTableName;
  }

  get cloudSubRecordId(): string {
    return this.cloudSubRecordId_;
  }

  set cloudSubRecordId(sourceId: string) {
    this.cloudSubRecordId_ = sourceId;
  }

  get cloudSubKey(): number {
    return this.cloudSubKey_;
  }

  set cloudSubKey(sourceSubkey: number) {
    this.cloudSubKey_ = sourceSubkey;
  }

  get subscribeId(): string {
    return this.subscribeId_;
  }

  set subscribeId(sourceSubscribeId: string) {
    this.subscribeId_ = sourceSubscribeId;
  }
}
