/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { NaturalStoreObjectSchema } from '../base/NaturalStoreObjectSchema';
import { MessageType } from './ProtoHelper';
import { SyncRequestProcessor } from './SyncRequestProcessor';
import { SyncTaskHandler } from './SyncTaskHandler';
import { SyncObjectRequest } from './request/SyncObjectRequest';
import { SyncQueryRequest } from './request/SyncQueryRequest';
import { SyncRequest } from './request/SyncRequest';
import {
  CloudObjectSyncResponse,
  QueryResponse,
  QueryType,
  SyncResult,
  TransactionResponse
} from './request/SyncResult';
import { ErrorCode } from '../utils/ErrorCode';
import { OperationType } from './utils/MessageType';
import { Utils } from '../utils/Utils';
import { HttpRequestTask } from './task/HttpRequestTask';
import { EncryptTaskManager } from './EncryptTaskManager';
import { NaturalBaseRef } from '../base/NaturalBaseRef';
import { SyncMessageType } from './utils/EntityTemplate';
import { SnapshotUpdateTask } from './task/SnapshotUpdateTask';
import { EncryptionInfoPushTask } from './task/EncryptionInfoPushTask';

const TAG = 'NaturalCloudSyncModule';

export class NaturalCloudSyncModule implements SyncTaskHandler {
  private subTunnelFail = false;
  private isInitiativeStop = false;
  private syncInstance: SyncRequestProcessor;
  private readonly encryptTaskManager: EncryptTaskManager;
  private readonly naturalBaseRef: NaturalBaseRef;

  public constructor(naturalBaseRef: NaturalBaseRef) {
    this.naturalBaseRef = naturalBaseRef;
    this.syncInstance = new SyncRequestProcessor(naturalBaseRef.getCertificateService());
    this.syncInstance.registerWebSocketCallBack(
      SyncMessageType.SnapshotUpdate,
      new SnapshotUpdateTask((errorCode: ErrorCode, result: any) => {})
    );
    this.syncInstance.registerWebSocketCallBack(
      SyncMessageType.EncryptionResponse,
      new EncryptionInfoPushTask()
    );
    this.syncInstance.registerConnectCallback(async () => {
      await this.onConnect();
    });
    this.syncInstance.registerDisconnectCallback((isInitiativeStop: boolean) => {
      this.onDisconnect(isInitiativeStop);
    });
    this.encryptTaskManager = new EncryptTaskManager(this.syncInstance, this.naturalBaseRef);
  }

  private async onConnect(): Promise<void> {
    Logger.info(TAG, `onConnect: subTunnelFail: ${this.subTunnelFail}`);
    if (this.subTunnelFail) {
      this.subTunnelFail = false;
      this.isInitiativeStop = false;
      await this.naturalBaseRef.onConnect();
    }
  }

  private onDisconnect(isInitiativeStop: boolean): void {
    this.isInitiativeStop = isInitiativeStop;
    Logger.warn(TAG, `onDisconnect isInitiativeStop:${this.isInitiativeStop}`);
    if (!this.isInitiativeStop) {
      this.subTunnelFail = true;
    }
  }

  public async disconnectWebSocket(): Promise<void> {
    await this.syncInstance.disConnectWebSocket();
  }

  public needToDisconnectWebsocket(): boolean {
    return this.syncInstance.needToDisconnectWebsocket();
  }

  public async onQuery(storeName: string, tableName: string, query: string): Promise<any[]> {
    return (
      (await this.processCRUDRequest(
        this.createSyncQueryRequest(storeName, tableName, query, QueryType.CONVENTIONAL_QUERY)
      )) as QueryResponse
    ).responseObject;
  }

  private createSyncQueryRequest(
    storeName: string,
    tableName: string,
    query: string,
    queryType: QueryType
  ): SyncQueryRequest {
    const request: SyncQueryRequest = new SyncQueryRequest();
    request.naturalStoreName = storeName;
    request.tableName = tableName;
    request.queryCondition = query;
    request.queryType = queryType;
    return request;
  }

  public async onUpsert(storeName: string, data: any[]): Promise<number> {
    return (
      (await this.processCRUDRequest(
        this.createSyncObjectRequest(
          storeName,
          MessageType.OBJECT_UPDATE,
          OperationType.SYNC_UPSERT,
          data
        )
      )) as CloudObjectSyncResponse
    ).successNumber;
  }

  public async onDelete(storeName: string, data: any[]): Promise<number> {
    return (
      (await this.processCRUDRequest(
        this.createSyncObjectRequest(
          storeName,
          MessageType.OBJECT_UPDATE,
          OperationType.SYNC_DELETE,
          data
        )
      )) as CloudObjectSyncResponse
    ).successNumber;
  }

  private createSyncObjectRequest(
    naturalStoreName: string,
    requestType: MessageType,
    operationType: OperationType,
    objectTypeList: any[]
  ): SyncObjectRequest {
    const request: SyncObjectRequest = new SyncObjectRequest();
    request.naturalStoreName = naturalStoreName;
    request.requestType = requestType;
    request.operationType = operationType;
    request.objList = objectTypeList;
    const objNames = new Set<string>();
    objectTypeList.forEach(obj => {
      objNames.add(Utils.getClassName(obj));
    });
    request.schemas = this.buildSchemas([...objNames]);
    return request;
  }

  private buildSchemas(schemaNames: string[]): NaturalStoreObjectSchema[] {
    const result: any[] = [];
    for (const schemaName of schemaNames) {
      const tableInfo = this.naturalBaseRef.getDefaultNaturalStore().getAppSchema().get(schemaName);
      if (tableInfo) {
        result.push(tableInfo);
      }
    }
    return result;
  }

  private async processCRUDRequest(
    request: SyncRequest
  ): Promise<CloudObjectSyncResponse | QueryResponse | TransactionResponse> {
    return new Promise<CloudObjectSyncResponse | QueryResponse | TransactionResponse>(
      (resolve, reject) => {
        this.syncInstance.process(
          new HttpRequestTask(
            request,
            this.naturalBaseRef.getEntireEncryption().GetEncryptVersion(),
            this.naturalBaseRef.getCertificateService(),
            (errorCode: ErrorCode, syncResult: SyncResult) => {
              if (errorCode !== ErrorCode.OK) {
                reject(errorCode);
                return;
              }
              resolve(syncResult.response as any);
            }
          )
        );
      }
    );
  }

  public getEncryptTaskManager(): EncryptTaskManager {
    return this.encryptTaskManager;
  }
}
