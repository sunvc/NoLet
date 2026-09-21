import { EncryptionKeyStatus } from './utils/EncryptInfo';

/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

export class EncryptionStatusMonitor {
  onUserCommandChanged!: () => any;

  onKeyChanged!: (status: EncryptionKeyStatus) => any;

  constructor(onUserCommandChanged: () => any, onKeyChanged: (status: EncryptionKeyStatus) => any) {
    this.onUserCommandChanged = onUserCommandChanged;
    this.onKeyChanged = onKeyChanged;
  }
}
