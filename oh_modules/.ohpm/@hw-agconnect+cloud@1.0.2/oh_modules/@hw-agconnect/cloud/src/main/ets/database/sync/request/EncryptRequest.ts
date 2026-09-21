/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
import { SyncRequest } from './SyncRequest';
import { EncryptInfo } from '../utils/EncryptInfo';
import { MessageSubType, MessageType } from '../utils/MessageType';
// @ts-ignore
import Long from 'long';

export class EncryptRequest extends SyncRequest {
  constructor(requestSubType: MessageSubType, requestInfo: EncryptInfo[], taskId: Long) {
    super();
    this.taskId_ = taskId;
    this.requestType = MessageType.ENCRYPTION_TASK;
    this.requestSubType = requestSubType;
    this.requestInfo_ = requestInfo;
  }

  private readonly requestInfo_: EncryptInfo[] = [];

  get requestInfo(): EncryptInfo[] {
    return this.requestInfo_;
  }
}
