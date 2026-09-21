/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { DatabaseZoneSnapshot } from '../DatabaseZoneSnapshot';

export class DatabaseZoneSnapshotImpl<T> implements DatabaseZoneSnapshot<T> {
  private snapshotObjects: T[];
  private upsertedObjects: T[];
  private deletedObjects: T[];

  constructor(snapshotObjects: T[], upsertedObjects: T[], deletedObjects: T[]) {
    this.snapshotObjects = snapshotObjects;
    this.upsertedObjects = upsertedObjects;
    this.deletedObjects = deletedObjects;
  }

  getSnapshotObjects(): T[] {
    return this.snapshotObjects;
  }

  setSnapshotObjects(snapshotObjects: T[]) {
    this.snapshotObjects = snapshotObjects;
  }

  getUpsertedObjects(): T[] {
    return this.upsertedObjects;
  }

  setUpsertedObjects(upsertedObjects: T[]) {
    this.upsertedObjects = upsertedObjects;
  }

  getDeletedObjects(): T[] {
    return this.deletedObjects;
  }

  setDeletedObjects(deletedObjects: T[]) {
    this.deletedObjects = deletedObjects;
  }
}
