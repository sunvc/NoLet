/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { SyncTask } from './SyncTask';
import { SyncRequest } from '../request/SyncRequest';
import { SyncResult } from '../request/SyncResult';
import { ErrorCode } from '../../utils/ErrorCode';
import { SyncRequestProcessor } from '../SyncRequestProcessor';

export abstract class WebSocketTask extends SyncTask {
  protected syncProcessor?: SyncRequestProcessor;

  protected constructor(
    syncRequest: SyncRequest,
    handle: (errorCode: ErrorCode, syncResult: SyncResult) => any,
    syncProcessor?: SyncRequestProcessor
  ) {
    super();
    this.syncRequest = syncRequest;
    this.handle = handle;
    this.syncProcessor = syncProcessor;
  }
}
