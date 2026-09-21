/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
import { SyncRequest } from './SyncRequest';
import { MessageType } from '../utils/MessageType';
import { ObjectWrapper } from '../ObjectWrapper';

export class SubscribeRequest extends SyncRequest {
  constructor() {
    super();
    this.requestType = MessageType.QUERY_SUB;
  }

  private subscribeDatas_: SubscribeData[] = [];

  get subscribeDatas(): SubscribeData[] {
    return this.subscribeDatas_;
  }

  set subscribeDatas(sourceDatas: SubscribeData[]) {
    this.subscribeDatas_ = sourceDatas;
  }
}

export class SubscribeData {
  private naturalStoreName_!: string;

  private tableName_!: string;

  private subscribeId_!: string;

  private subscribeCondition_!: string;

  private snapshotObjs_: any[] = [];

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

  get subscribeId(): string {
    return this.subscribeId_;
  }

  set subscribeId(sourceSubScribeId: string) {
    this.subscribeId_ = sourceSubScribeId;
  }

  get subscribeCondition(): string {
    return this.subscribeCondition_;
  }

  set subscribeCondition(sourceSubscribeConditions: string) {
    this.subscribeCondition_ = sourceSubscribeConditions;
  }

  get snapshotObjs(): ObjectWrapper[] {
    return this.snapshotObjs_;
  }

  set snapshotObjs(snapshotObjs: ObjectWrapper[]) {
    this.snapshotObjs_ = snapshotObjs;
  }
}
