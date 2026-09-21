/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

export interface DatabaseZoneSnapshot<T> {
  /**
   * Obtains all object data from snapshots.
   */
  getSnapshotObjects(): T[];

  /**
   * Obtains the object data added or modified in a snapshot.
   */
  getUpsertedObjects(): T[];

  /**
   * Obtains the newly deleted object data from the snapshot.
   */
  getDeletedObjects(): T[];
}
