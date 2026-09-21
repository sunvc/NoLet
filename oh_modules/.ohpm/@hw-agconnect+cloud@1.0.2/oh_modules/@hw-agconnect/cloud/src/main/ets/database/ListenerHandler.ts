/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

export interface ListenerHandler {
  /**
   * Deregisters the snapshot listener.
   */
  remove(): Promise<void>;
}
