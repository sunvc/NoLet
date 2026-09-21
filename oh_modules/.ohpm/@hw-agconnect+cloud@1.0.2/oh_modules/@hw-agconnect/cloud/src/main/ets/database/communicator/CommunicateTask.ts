/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { SyncTask } from '../sync/task/SyncTask';

const TAG = 'CommunicateTask';

/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
export class CommunicateTask {
  protected func!: () => any;
  private delayMs = 0;
  private isCanceled = false;
  private readonly handle: any;
  private readonly task: SyncTask;

  constructor(task: SyncTask, delayMs: number, handle?: any) {
    this.task = task;
    this.func = task.request;
    this.delayMs = delayMs;
    this.handle = handle;
  }

  execute() {
    const handle = this.handle;
    if (!this.isCanceled) {
      try {
        this.func.call(this.task);
      } catch (error) {
        Logger.error(TAG, error);
        handle?.handle(false, error);
      }
    }
  }

  getDelayMs() {
    return this.delayMs;
  }

  cleanDelayMs() {
    this.delayMs = 0;
  }

  cancel() {
    this.isCanceled = true;
  }
}
