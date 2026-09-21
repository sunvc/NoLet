/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { MessageSubType, MessageType } from '../utils/MessageType';
// @ts-ignore
import Long from 'long';
import { SyncRequestProcessor } from '../SyncRequestProcessor';
import { NaturalStoreObjectSchema } from '../../base/NaturalStoreObjectSchema';

export class SyncRequest {
  private requestType_!: MessageType;
  private requestSubType_?: MessageSubType;
  private naturalStoreName_?: string;
  protected taskId_: Long = SyncRequestProcessor.generateTaskId();
  private encryptionVersion_ = 0;
  private schemas_: NaturalStoreObjectSchema[] = [];
  private traceId_: string = SyncRequestProcessor.generalTraceId();

  get schemas(): NaturalStoreObjectSchema[] {
    return this.schemas_;
  }

  set schemas(sourceSchemas: NaturalStoreObjectSchema[]) {
    this.schemas_ = sourceSchemas;
  }

  get requestSubType(): MessageSubType | undefined {
    return this.requestSubType_;
  }

  set requestSubType(sourceType: MessageSubType | undefined) {
    this.requestSubType_ = sourceType;
  }

  get requestType(): MessageType {
    return this.requestType_;
  }

  set requestType(sourceType: MessageType) {
    this.requestType_ = sourceType;
  }

  get traceId(): string {
    return this.traceId_;
  }

  get naturalStoreName(): string | undefined {
    return this.naturalStoreName_;
  }

  set naturalStoreName(sourceName: string | undefined) {
    this.naturalStoreName_ = sourceName;
  }

  get taskId(): Long {
    return this.taskId_;
  }

  set taskId(taskId: Long) {
    this.taskId_ = taskId;
  }

  get encryptionVersion(): number {
    return this.encryptionVersion_;
  }

  set encryptionVersion(version: number) {
    this.encryptionVersion_ = version;
  }
}
