/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { ErrorCode } from '../../utils/ErrorCode';

const TAG = 'CallbackTask';

export class CallbackTask {
  private timerHandler: any = undefined;
  private timeoutMs = 0;
  private isDone = false;

  constructor() {}

  private timeoutMonitor(reject: (reason: any) => void) {
    Logger.debug(TAG, `timeoutMonitor: enter`);
    if (this.timeoutMs > 0) {
      this.timerHandler = setTimeout(() => {
        if (this.timerHandler) {
          clearTimeout(this.timerHandler);
        }
        Logger.info(TAG, `timeoutMonitor: setTimeout reject isDone:${this.isDone}`);
        if (!this.isDone) {
          Logger.info(TAG, `timeoutMonitor: setTimeout reject`);
          reject(ErrorCode.COMMUNICATOR_QUEUE_FULL);
        }
      }, this.timeoutMs);
    }
  }

  private async execute(handle?: () => Promise<any>): Promise<any> {
    return new Promise((resolve, reject) => {
      this.timeoutMonitor(reject);
      (async () => {
        Logger.info(TAG, `executeWithTimeout: handle start calling`);
        return handle?.call(null);
      })()
        .then(result => {
          this.isDone = true;
          if (this.timerHandler) {
            clearTimeout(this.timerHandler);
          }
          Logger.debug(
            TAG,
            `executeWithTimeout: handle finished calling: resultCode = ${result.resultCode}`
          );
          resolve(result);
        })
        .catch(reason => {
          this.isDone = true;
          reject(reason);
        });
    });
  }

  async executeWithTimeout(timeoutMs: number, handle?: () => Promise<any>): Promise<any> {
    this.timeoutMs = timeoutMs;
    Logger.debug(TAG, `executeWithTimeout: enter`);
    return new Promise((resolve, reject) => {
      this.execute(handle)
        .then(result => {
          Logger.debug(TAG, `executeWithTimeout: execute done resultCode = ${result.resultCode}`);
          resolve(result);
        })
        .catch(e => {
          if (!this.isDone) {
            Logger.error(TAG, `executeWithTimeout: timeout!`);
          }
          Logger.debug(TAG, `executeWithTimeout: execute done resultCode = ${e.resultCode}`);
          resolve(e);
        });
    });
  }
}
