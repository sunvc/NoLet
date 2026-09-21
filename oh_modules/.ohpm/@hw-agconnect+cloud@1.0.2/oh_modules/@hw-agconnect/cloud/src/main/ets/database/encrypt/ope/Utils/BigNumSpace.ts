/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
import BigNumber from 'bignumber.js';

/**
 * Data structure of Big int space
 */
export class BigNumSpace {
  // left boundary in plaintext space
  inEdge: BigNumber;
  // interval size in plaintext space
  inSize: BigNumber;
  // left boundary in cipher text space
  outEdge: BigNumber;
  // interval size in cipher text space
  outSize: BigNumber;
  // value in plaintext space
  value: BigNumber;
  // output value length
  outLen: number;

  constructor() {
    this.inEdge = new BigNumber(0);
    this.inSize = new BigNumber(0);
    this.outSize = new BigNumber(0);
    this.outEdge = new BigNumber(0);
    this.value = new BigNumber(0);
    this.outLen = 0;
  }

  static copy(bigIntSpace: BigNumSpace): BigNumSpace {
    const copyInstance = new BigNumSpace();
    copyInstance.value = bigIntSpace.value;
    copyInstance.inSize = bigIntSpace.inSize;
    copyInstance.inEdge = bigIntSpace.inEdge;
    copyInstance.outEdge = bigIntSpace.outEdge;
    copyInstance.outSize = bigIntSpace.outSize;
    copyInstance.outLen = bigIntSpace.outLen;
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
