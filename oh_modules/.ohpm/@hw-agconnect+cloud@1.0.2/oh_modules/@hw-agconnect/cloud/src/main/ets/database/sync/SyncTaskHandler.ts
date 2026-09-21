/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

export interface SyncTaskHandler {
  onUpsert(storeName: string, data: any[]): Promise<number>;

  onDelete(storeName: string, data: any[]): Promise<number>;

  onQuery(storeName: string, tableName: string, query: string): Promise<any[]>;
}
