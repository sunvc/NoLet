/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { DatabaseCollection } from './DatabaseCollection';
import { DatabaseException } from './DatabaseException';
import { DatabaseZoneQuery } from './DatabaseZoneQuery';

export { DatabaseCollection, DatabaseException, DatabaseZoneQuery };

export interface DatabaseConfig {
  objectTypeInfo: ObjectTypeInfo;
  zoneName: string;
  traceId?: string;
  syncMode?: number;
}

export interface ObjectTypeInfo {
  schemaVersion: number;
  permissions: any;
  objectTypes: any;
}

export interface Database {
  collection<T>(clazz: new () => T): DatabaseCollection<T>;
}
