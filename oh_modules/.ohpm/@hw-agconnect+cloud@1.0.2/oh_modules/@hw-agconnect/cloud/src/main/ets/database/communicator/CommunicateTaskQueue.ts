/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { CommunicateTask } from './CommunicateTask';

const INVALID_COMMUNICATOR_STATUS = -1;
const TAG = 'CommunicateTaskQueue';

export class CommunicateTaskQueue {
  private readonly tasks: CommunicateTask[] = [];
  private taskId = 0;
  private head = 0;
  private timerHandle: any;
  private isShutdown = false;
  private isExecuting = false;

  constructor() {}

  enqueueTask(newTask: CommunicateTask): number {
    if (this.isShutdown) {
      Logger.info(TAG, '[CommunicateTaskQueue] enqueueTask fail due to shutdown!');
      return INVALID_COMMUNICATOR_STATUS;
    }
    const taskId = ++this.taskId;
    this.tasks.push(newTask);
    if (!this.isExecuting) {
      this.process();
    }
    return taskId;
  }

  protected process() {
    this.isExecuting = true;
    const current = this.tasks.splice(0, 1);
    if (current.length === 0) {
      this.isExecuting = false;
    } else {
      this.head++;
      const task = current[0];
      this.timerHandle = setTimeout(async () => {
        if (!this.timerHandle) {
          clearTimeout(this.timerHandle);
        }
        task.execute();
        this.process();
      }, task.getDelayMs());
    }
  }
}
