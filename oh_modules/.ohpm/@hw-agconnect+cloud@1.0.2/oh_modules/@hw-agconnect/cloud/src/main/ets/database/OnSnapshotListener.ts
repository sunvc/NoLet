/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { DatabaseException } from './DatabaseException';
import { DatabaseZoneSnapshot } from './DatabaseZoneSnapshot';

/**
 * Defines a snapshot listener API. To listen on snapshots,
 * you must inherit the API to implement the desired listener.
 * When this API is implemented, subscribeSnapshot() needs to be called to register the listener.
 */
export interface OnSnapshotListener<T> {
  /**
   * After the listener is registered, Cloud DB will automatically call the onSnapshot() method to perform
   * user-defined operations when the snapshot data that is listened on is changed.
   * @param snapshot Changed snapshot objects, including full snapshot data, newly written object sets,
   * and newly deleted object sets.
   * @param exception when you are notified of snapshot changes, if any exception occurs,
   * this parameter is not null.You can obtain relevant error information based on the exception object e.
   */
  onSnapshot(snapshot: DatabaseZoneSnapshot<T>, exception: DatabaseException): void;
}
