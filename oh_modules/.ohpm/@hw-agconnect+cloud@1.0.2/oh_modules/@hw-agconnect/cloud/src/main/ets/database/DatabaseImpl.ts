/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { NaturalBase } from './base/NaturalBase';
import { SyncRequestProcessor } from './sync/SyncRequestProcessor';
import { ErrorCode } from './utils/ErrorCode';
import { Utils } from './utils/Utils';
import { NaturalStore } from './base/NaturalStore';
import { DatabaseCollection } from './DatabaseCollection';
import { Database, DatabaseConfig } from './Database';
import { ExceptionUtil } from './utils/ExceptionUtil';

const TAG = 'DatabaseImpl';

export class DatabaseImpl implements Database {
  private naturalStore: NaturalStore;
  private naturalBase: NaturalBase;
  private zoneName: string;
  private traceId: string;
  public readonly zoneId: string;

  constructor(region: string, databaseConfig: DatabaseConfig) {
    this.naturalBase = new NaturalBase(region);
    this.naturalBase.createObjectType(databaseConfig.objectTypeInfo);
    this.zoneName = databaseConfig.zoneName;
    this.traceId = databaseConfig.traceId;
    this.zoneId = Utils.generateUUID();
    this.naturalStore = this.openNaturalStore(this.zoneName);
    SyncRequestProcessor.setTraceId(this.traceId);
  }

  private openNaturalStore(zoneName: string): NaturalStore {
    let store;
    let result = this.naturalBase.openNaturalStore(zoneName);
    if (result.exceptionCode === ErrorCode.OK) {
      store = result.naturalStore!;
      store.references.add(this.zoneId);
    } else {
      Logger.error(TAG, `openNaturalStore: Failed to create or open a naturalStore.`);
      throw ExceptionUtil.build(`openNaturalStore failed.`);
    }

    return store;
  }

  public collection<T>(clazz: new () => T): DatabaseCollection<T> {
    Utils.checkNotNull(clazz, `Entity class must not be null.`);
    return new DatabaseCollection(this.naturalStore, clazz);
  }
}
