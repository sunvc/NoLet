/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';

const TAG = `SequenceTaskQueue`;

export class SequenceTaskQueue {
  private tasks: SequenceTask[] = [];
  private isExecuting = false;

  public scheduleProcess(task: SequenceTask) {
    Logger.debug(TAG, `scheduleProcess start: ${this.isExecuting}`);
    this.tasks.push(task);
    if (!this.isExecuting) {
      this.process();
    }
  }

  private process() {
    this.isExecuting = true;
    Logger.debug(TAG, `process start length: ${this.tasks.length}`);
    if (this.tasks.length) {
      const task = this.tasks.shift();
      task?.execute().then(() => {
        this.process();
      });
    } else {
      this.isExecuting = false;
    }
  }
}

export class SequenceTask {
  private func!: any;

  constructor(executeFunction: (data: unknown[]) => any) {
    this.func = executeFunction;
  }

  execute() {
    return this.func.call(null);
  }
}
