/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { NaturalCloudSyncModule } from '../sync/NaturalCloudSyncModule';
import { EncryptInfo, EncryptResult } from '../sync/utils/EncryptInfo';
import { NaturalBaseRef } from '../base/NaturalBaseRef';

export class NaturalCloudStorage {
  private readonly naturalCloudSyncModule: NaturalCloudSyncModule;

  public constructor(naturalBaseRef: NaturalBaseRef) {
    this.naturalCloudSyncModule = new NaturalCloudSyncModule(naturalBaseRef);
  }

  public async executeUpsert(objects: any[], naturalStoreName: string): Promise<number> {
    return await this.naturalCloudSyncModule.onUpsert(naturalStoreName, objects);
  }

  public async executeDelete(objects: any[], naturalStoreName: string): Promise<number> {
    return await this.naturalCloudSyncModule.onDelete(naturalStoreName, objects);
  }

  public async executeQuery<T>(
    naturalStoreName: string,
    schemaName: string,
    queryCondition: string
  ): Promise<T[]> {
    return await this.naturalCloudSyncModule.onQuery(naturalStoreName, schemaName, queryCondition);
  }

  public needToDisconnectWebsocket(): boolean {
    return this.naturalCloudSyncModule.needToDisconnectWebsocket();
  }

  public async disconnectWebSocket(): Promise<void> {
    await this.naturalCloudSyncModule.disconnectWebSocket();
  }

  public async querySaltValue(): Promise<EncryptResult> {
    return await this.naturalCloudSyncModule.getEncryptTaskManager().querySaltValue();
  }

  public async queryDataKeyCipherText(requestInfo: EncryptInfo): Promise<EncryptResult> {
    return await this.naturalCloudSyncModule
      .getEncryptTaskManager()
      .queryDataKeyCipherText(requestInfo);
  }

  public async insertEncryptedInfo(insertEncryptInfo: EncryptInfo): Promise<EncryptResult> {
    return await this.naturalCloudSyncModule
      .getEncryptTaskManager()
      .insertEncryptedInfo(insertEncryptInfo);
  }

  public async updateEncryptedInfo(
    oldEncryptInfo: EncryptInfo,
    newEncryptInfo: EncryptInfo
  ): Promise<EncryptResult> {
    return await this.naturalCloudSyncModule
      .getEncryptTaskManager()
      .updateEncryptedInfo(oldEncryptInfo, newEncryptInfo);
  }
}
