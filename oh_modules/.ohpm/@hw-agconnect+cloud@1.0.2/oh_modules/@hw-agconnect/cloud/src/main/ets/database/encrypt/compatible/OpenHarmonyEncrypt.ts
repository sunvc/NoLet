/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { BaseEncrypt } from './BaseEncrypt';
import { ExceptionUtil } from '../../utils/ExceptionUtil';

export class OpenHarmonyEncrypt implements BaseEncrypt {
  public async decrypt(
    cipherText: Uint8Array,
    key: Uint8Array,
    iv: Uint8Array
  ): Promise<Uint8Array> {
    throw ExceptionUtil.build('OpenHarmony platform is not support encryption feature');
  }

  public async encrypt(
    plainText: Uint8Array,
    key: Uint8Array,
    iv: Uint8Array
  ): Promise<Uint8Array> {
    throw ExceptionUtil.build('OpenHarmony platform is not support encryption feature');
  }

  public generateRandom(num: number): Uint8Array {
    throw ExceptionUtil.build('OpenHarmony platform is not support encryption feature');
  }
}
