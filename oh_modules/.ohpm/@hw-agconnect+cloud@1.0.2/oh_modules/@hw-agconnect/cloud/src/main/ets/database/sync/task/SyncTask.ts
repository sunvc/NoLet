/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { ErrorCode } from '../../utils/ErrorCode';
import { SyncResult } from '../request/SyncResult';
import { SyncRequest } from '../request/SyncRequest';

export abstract class SyncTask {
  handle!: (errorCode: ErrorCode, syncResult: SyncResult) => any;

  protected syncRequest!: SyncRequest;

  abstract request(): void;
}
