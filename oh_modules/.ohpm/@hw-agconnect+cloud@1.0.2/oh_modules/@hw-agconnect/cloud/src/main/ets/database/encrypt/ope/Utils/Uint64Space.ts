/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
// @ts-ignore
import Long from 'long';

/**
 * Data structure of Unit64 space. (Unsigned Long)
 */
export class Uint64Space {
  // left boundary in plaintext space
  inEdge: Long;
  // interval size in plaintext space
  inSize: Long;
  // left boundary in cipher text space
  outEdge: Long;
  // interval size in cipher text space
  outSize: Long;
  // value in plaintext space
  value: Long;
  // output value length
  outLen: number;

  constructor() {
    this.inEdge = Long.UZERO;
    this.inSize = Long.UZERO;
    this.outEdge = Long.UZERO;
    this.outSize = Long.UZERO;
    this.value = Long.UZERO;
    this.outLen = 0;
  }

  static copy(unit64Space: Uint64Space): Uint64Space {
    const copyInstance = new Uint64Space();
    copyInstance.inEdge = unit64Space.inEdge;
    copyInstance.inSize = unit64Space.inSize;
    copyInstance.outEdge = unit64Space.outEdge;
    copyInstance.outSize = unit64Space.outSize;
    copyInstance.value = unit64Space.value;
    copyInstance.outLen = unit64Space.outLen;
    return copyInstance;
  }

  public toString() {
    return (
      'inEdge: ' +
      this.inEdge.toString(10) +
      ', inSize: ' +
      this.inSize.toString(10) +
      ', outEdge: ' +
      this.outEdge.toString(10) +
      ', outSize: ' +
      this.outSize.toString(10) +
      ', value: ' +
      this.value.toString(10) +
      ', outLen: ' +
      this.outLen
    );
  }
}
