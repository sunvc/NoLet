/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

export interface WebSocketAdapter {
  connect(object: unknown): void;

  close(object?: unknown): void;

  sendMessage(object: unknown): void;
}
