/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

/**
 * Data structure of Floating point parameter
 */
export class FloatPointParameter {
  // radix number sign positive or negative in floating point value
  radixSign: number;
  // radix number length in floating point value
  radixLen: number;
  // exponent sign positive or negative in floating point value
  expSign: number;
  // exponent length in floating point value
  expLen: number;
  // normalized exponent value
  normalizedExp: number;
  // normalized exponent size
  normalizedSize: number;
  // floating point value length
  effectiveLen: number;

  constructor() {
    this.radixSign = 0;
    this.radixLen = 0;
    this.expSign = 0;
    this.expLen = 0;
    this.normalizedExp = 0;
    this.normalizedSize = 1;
    this.effectiveLen = 0;
  }

  public toString() {
    return (
      'radixSign: ' +
      this.radixSign +
      ', radixLen: ' +
      this.radixLen +
      ', expSign: ' +
      this.expSign +
      ', expLen: ' +
      this.expLen +
      ', normalizedExp: ' +
      this.normalizedExp +
      ', normalizedSize: ' +
      this.normalizedSize +
      ', effectiveLen: ' +
      this.effectiveLen
    );
  }
}
