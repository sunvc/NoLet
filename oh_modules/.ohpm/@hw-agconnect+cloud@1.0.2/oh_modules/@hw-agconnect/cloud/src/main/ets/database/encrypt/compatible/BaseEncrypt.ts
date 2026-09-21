/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

export interface BaseEncrypt {
  decrypt(cipherText: Uint8Array, key: Uint8Array, iv: Uint8Array): Promise<Uint8Array>;

  encrypt(plainText: Uint8Array, key: Uint8Array, iv: Uint8Array): Promise<Uint8Array>;

  generateRandom(num: number): Uint8Array;
}
