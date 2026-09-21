/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { Uint64Space } from './Utils/Uint64Space';
import { BigNumSpace } from './Utils/BigNumSpace';
// @ts-ignore
import Long from 'long';
import { OpeDataType } from './Utils/OpeDataType';
import { OpeTypeConversion } from './OpeTypeConversion';
import BigNumber from 'bignumber.js';
import { Utils } from '../../utils/Utils';
import { CloudDBCryptoJS } from '../crypto/CloudDBCryptoJS';

const TAG = 'OpeGenerator';
const CryptoJS = CloudDBCryptoJS.getCryptoJS();

/**
 * This class is used to generate order-preserving value according to the input value
 */
export class OpeGenerator {
  private static readonly NUMBER_RADIX_DECIMAL = 10;
  private static readonly INT8_DEFAULT_DIGIT = 8;
  // Need to smooth the distribution of cipher text
  private static readonly CIPHER_TEXT_SAMPLE_REDUNDANCY = 11;
  // The max length to calculate entire ope value
  private static readonly MAX_ENTIRE_OPE_LEN = 2400;
  // Ope calculate uint64 error
  private static readonly OPE_UINT64_ERROR = Long.UZERO;
  // Truncated byte length for string
  private static readonly STRING_TRUNCATED_BYTE_LEN = 16;

  // @ts-ignore
  public generateOpeValue(input: string, inLen: number, type: number, key: any): string {
    if (input == null || inLen == null || inLen <= 0 || key == null || type == null) {
      Logger.warn(TAG, 'generateOpeValue: input parameter is invalid.');
      throw Error('generateOpeValue: input parameter is invalid.');
    }

    this.inputVerification(input, type);

    let opeValue: string;
    switch (type) {
      case OpeDataType.OPE_TYPE_BOOL:
      case OpeDataType.OPE_TYPE_INT8:
      case OpeDataType.OPE_TYPE_INT16:
      case OpeDataType.OPE_TYPE_INT32:
      case OpeDataType.OPE_TYPE_FLOAT: {
        opeValue = this.generateOpeValueByUint64(input, type, key);
        break;
      }
      case OpeDataType.OPE_TYPE_INT64:
      case OpeDataType.OPE_TYPE_DATE:
      case OpeDataType.OPE_TYPE_DOUBLE: {
        opeValue = this.generateOpeValueByBigNum(input, inLen, type, key);
        break;
      }
      case OpeDataType.OPE_TYPE_STRING: {
        opeValue = this.generateOpeValueForString(input, inLen, type, key);
        break;
      }
      default:
        Logger.warn(TAG, 'generateOpeValue: type: ' + type + ' is error.');
        throw Error('generateOpeValue: type: ' + type + ' is error.');
    }
    if (opeValue.length <= 0) {
      Logger.warn(TAG, 'generateOpeValue: generate ope value failed');
      throw Error('generateOpeValue: generate ope value failed');
    }
    return opeValue;
  }

  private generateOpeValueByUint64(
    input: string,
    type: number,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): string {
    const uint64Space: Uint64Space = new Uint64Space();
    // Convert different data type to cipher text space in uint64
    const rst = OpeTypeConversion.convertToOpeDataSpaceUint64(input, type, uint64Space);
    if (rst !== OpeTypeConversion.OPE_SUCCESS) {
      Logger.warn(TAG, 'generateOpeValueByUint64: convert to uint64 space failed');
      throw Error('generateOpeValueByUint64: convert to uint64 space failed');
    }
    // According to the cipher text space in uint64, calculate ope value
    return this.getOpeValueByUint64(key, uint64Space);
  }

  private generateOpeValueByBigNum(
    input: Uint8Array | string,
    inLen: number,
    type: number,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): string {
    const bigNumSpace: BigNumSpace = new BigNumSpace();
    // Convert different data type to cipher text in bigNum
    const rst = OpeTypeConversion.convertToOpeDataSpaceBigNum(input, inLen, type, bigNumSpace);
    if (rst !== OpeTypeConversion.OPE_SUCCESS) {
      Logger.warn(TAG, 'generateOpeValueByUint64: convert to bigNum space failed');
      throw Error('generateOpeValueByUint64: convert to bigNum space failed');
    }

    const opeValue: string = this.getOpeValueByBigNum(key, bigNumSpace);

    // According to the cipher text space in bigNum, calculate ope value
    if (opeValue.length <= 0) {
      Logger.warn(TAG, 'generateOpeValueByBigNum: generate ope value by bigNum failed');
      throw Error('generateOpeValueByBigNum: generate ope value by bigNum failed');
    }

    return opeValue;
  }

  private generateOpeValueForString(
    input: string,
    inLen: number,
    type: number,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): string {
    const uint8Array: Uint8Array = Utils.stringToUint8Array(input);
    const inStrLen = uint8Array.length === 0 ? 1 : uint8Array.length;
    let inLenTemp = inStrLen;
    let truncateCnt = (inStrLen - 1) / OpeGenerator.STRING_TRUNCATED_BYTE_LEN + 1;
    truncateCnt = Math.floor(truncateCnt);
    let outLen = 0;
    let textLen;
    let opeValue = '';
    // When string length exceed the truncated length, it will cyclic to truncate and joint for the entire ope value
    for (let i = 0; i < truncateCnt; i++) {
      if (inLenTemp > OpeGenerator.STRING_TRUNCATED_BYTE_LEN) {
        inLenTemp -= OpeGenerator.STRING_TRUNCATED_BYTE_LEN;
        textLen = OpeGenerator.STRING_TRUNCATED_BYTE_LEN;
      } else {
        textLen = inLenTemp;
      }
      const subUint8Array = uint8Array.subarray(
        i * OpeGenerator.STRING_TRUNCATED_BYTE_LEN,
        (i + 1) * OpeGenerator.STRING_TRUNCATED_BYTE_LEN
      );
      const temp = this.generateOpeValueByBigNum(subUint8Array, textLen, type, key);
      if (temp.length <= 0 || outLen + temp.length > OpeGenerator.MAX_ENTIRE_OPE_LEN) {
        Logger.warn(
          TAG,
          'generateOpeValueForString: generate ope value by bigNum failed, opeValueLen: ' +
            temp.length +
            ' truncateCnt: ' +
            truncateCnt
        );
        throw Error(
          'generateOpeValueForString: generate ope value by bigNum failed, opeValueLen: ' +
            temp.length +
            ' truncateCnt: ' +
            truncateCnt
        );
      }
      opeValue += temp;
      outLen += temp.length;
    }
    return opeValue;
  }

  // @ts-ignore
  private getOpeValueByUint64(key: CryptoJS.lib.WordArray, uint64Space: Uint64Space): string {
    const opeValue: Long = this.calculateOpeValueByUint64(uint64Space, key);
    if (opeValue.equals(OpeGenerator.OPE_UINT64_ERROR)) {
      Logger.warn(TAG, 'getOpeValueByUint64: calculate ope value by uint64 fail.');
      throw Error('getOpeValueByUint64: calculate ope value by uint64 fail.');
    }

    // If textResult is shorter than outLen, front position will be padding '0'.
    return (Array(uint64Space.outLen).join('0') + opeValue.toString(16).toUpperCase()).slice(
      -uint64Space.outLen
    );
  }

  // @ts-ignore
  private getOpeValueByBigNum(key: CryptoJS.lib.WordArray, bigNumSpace: BigNumSpace): string {
    const opeValue: BigNumber = this.calculateOpeValueByBigNum(bigNumSpace, key);
    // Convert bigNum to hexadecimal string.
    const textResult: string = opeValue.toString(16);

    // If text result is shorter than outLen, front position will be padding '0'.
    return (Array(bigNumSpace.outLen).join('0') + textResult.toUpperCase()).slice(
      -bigNumSpace.outLen
    );
  }

  // @ts-ignore
  private calculateOpeValueByUint64(uint64Space: Uint64Space, key: CryptoJS.lib.WordArray): Long {
    const opeValue: Long = Long.fromNumber(0);
    while (uint64Space.inSize.greaterThanOrEqual(1)) {
      if (
        uint64Space.value.lessThan(uint64Space.inEdge) ||
        uint64Space.value.greaterThanOrEqual(uint64Space.inEdge.add(uint64Space.inSize))
      ) {
        Logger.warn(TAG, 'calculateOpeValueByUint64: value out of range by uint64.');
        throw Error('calculateOpeValueByUint64: value out of range by uint64.');
      }

      // By Dichotomy, plaintext space equal to cipher text space size, find the ope value in cipher text space.
      if (uint64Space.inSize.equals(uint64Space.outSize)) {
        return uint64Space.outEdge.add(uint64Space.value).subtract(uint64Space.inEdge);
      }

      // When plaintext space size equal to one, find the ope value by uniform sample.
      if (uint64Space.inSize.equals(1)) {
        return this.uniformSampleInUint64(uint64Space.value, uint64Space, key);
      }

      // Calculate the mid value
      const mid: Long = uint64Space.inEdge.add(uint64Space.inSize.subtract(1).divide(2));

      // Using uniform sample,
      // calculate cipher text value in cipher text space by the mid value of plaintext space.
      // Then according to dichotomy, shorten the interval of plaintext space and cipher text space.
      // By recursive call, find the cipher text value that corresponding plaintext value finally.
      const sampleResult = this.uniformSampleInUint64(mid, Uint64Space.copy(uint64Space), key);

      // According to value and mid value,
      // shorten the interval of plaintext space and cipher text space by dichotomy.
      if (uint64Space.value.lessThanOrEqual(mid)) {
        // inSize = mid - inEdge + 1
        uint64Space.inSize = mid.subtract(uint64Space.inEdge).add(1);
        // outSize = sampleResult - outEdge + 1
        uint64Space.outSize = sampleResult.subtract(uint64Space.outEdge).add(1);
      } else {
        // inSize = inEdge + inSize - 1 - mid
        uint64Space.inSize = uint64Space.inEdge.add(uint64Space.inSize).subtract(1).subtract(mid);
        // outSize = outEdge + outSize - 1 - sampleResult
        uint64Space.outSize = uint64Space.outEdge
          .add(uint64Space.outSize)
          .subtract(1)
          .subtract(sampleResult);
        uint64Space.inEdge = mid.add(1);
        uint64Space.outEdge = sampleResult.add(1);
      }
    }
    return opeValue;
  }

  private uniformSampleInUint64(
    value: Long,
    uint64Space: Uint64Space,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): Long {
    if (!uint64Space.inSize.equals(1)) {
      // Reserve enough redundancy size for left and right interval in cipher text space
      const redundancySize: Long = uint64Space.inSize
        .multiply(OpeGenerator.CIPHER_TEXT_SAMPLE_REDUNDANCY)
        .divide(OpeGenerator.NUMBER_RADIX_DECIMAL);
      if (redundancySize.greaterThan(uint64Space.outSize)) {
        uint64Space.outEdge = uint64Space.outEdge.add(value).subtract(uint64Space.inEdge);
        uint64Space.outSize = uint64Space.outSize.subtract(uint64Space.inSize).subtract(1);
      } else {
        uint64Space.outSize = uint64Space.outSize.add(1).subtract(redundancySize);
        // outEdge = outEdge + (value - inEdge) * redundancy / 10
        uint64Space.outEdge = uint64Space.outEdge.add(
          value
            .subtract(uint64Space.inEdge)
            .multiply(OpeGenerator.CIPHER_TEXT_SAMPLE_REDUNDANCY)
            .divide(OpeGenerator.NUMBER_RADIX_DECIMAL)
        );
      }
    }

    if (uint64Space.outSize.equals(1)) {
      return uint64Space.outEdge;
    }

    // coin means pseudorandom number
    const coin: string = this.calculateCoinByUint64(value, uint64Space, key);
    let mid: Long;
    let index = 0;
    while (uint64Space.outSize.greaterThan(1)) {
      mid = uint64Space.outEdge.add(uint64Space.outSize.subtract(1).divide(2));
      if (coin.charAt(index) === '0') {
        uint64Space.outSize = mid.subtract(uint64Space.outEdge).add(1);
      } else {
        // outSize = outEdge + (outSize - 1) - mid
        uint64Space.outSize = uint64Space.outEdge
          .add(uint64Space.outSize.subtract(1))
          .subtract(mid);
        uint64Space.outEdge = mid.add(1);
      }
      index++;
    }
    return uint64Space.outEdge;
  }

  private calculateCoinByUint64(
    value: Long,
    uint64Space: Uint64Space,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): string {
    // Taking ope key and mid value of plaintext space as coin seed, to calculate hash value by SHA256
    // Then add hash value to the coin value by shifting, coin length is determined by outSize.
    // In one word, the mid value in plaintext space, corresponding to the coin value in cipher text space.
    const valueWordArray = CryptoJS.enc.Utf8.parse(value.toString(10));
    const coinSeedWordArray = valueWordArray.concat(key);

    const sha256Result: string = CryptoJS.SHA256(coinSeedWordArray).toString(CryptoJS.enc.Hex);
    // coinLen = int((log2(uint64Space.outSize) + 1)) / INT8_DEFAULT_DIGIT + 1
    const coinLen =
      Math.floor(
        (Math.floor(Math.log2(uint64Space.outSize.toNumber())) + 1) /
          OpeGenerator.INT8_DEFAULT_DIGIT
      ) + 1;
    let coin = '';
    // In C++ version,
    // the data structure is unit8 char array, here only support Hex string, so the coinLen should time 2.
    for (let i = 0; i < coinLen; i++) {
      coin += this.hex2binForUint64(sha256Result.substring(i * 2, (i + 1) * 2));
    }

    return coin;
  }

  private calculateOpeValueByBigNum(
    bigNumSpace: BigNumSpace,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): BigNumber {
    const opeValueByBigNum: BigNumber = new BigNumber(0);
    while (bigNumSpace.inSize.gte(1)) {
      if (
        bigNumSpace.value.lt(bigNumSpace.inEdge) ||
        bigNumSpace.value.gte(bigNumSpace.inEdge.plus(bigNumSpace.inSize))
      ) {
        Logger.warn(TAG, 'calculateOpeValueByBigNum: value out of range by bigNum');
        throw Error('calculateOpeValueByBigNum: value out of range by bigNum');
      }

      // By Dichotomy, plaintext space equal to cipher text space size, find the ope value in cipher text space.
      if (bigNumSpace.inSize.eq(bigNumSpace.outSize)) {
        // opeValue = bigNumSpace.outEdge + bigNumSpace.value - bigNumSpace.inEdge
        return bigNumSpace.outEdge.plus(bigNumSpace.value).minus(bigNumSpace.inEdge);
      }
      // When plaintext space size equal to one, find the ope value by uniform sample.
      if (bigNumSpace.inSize.eq(1)) {
        return this.uniformSampleInBigNum(bigNumSpace.value, bigNumSpace, key);
      }

      // Calculate the mid value
      const mid: BigNumber = bigNumSpace.inEdge.plus(
        bigNumSpace.inSize.minus(1).dividedToIntegerBy(2)
      );

      // Using uniform sample,
      // calculate cipher text value in cipher text space by the mid value of plaintext space.
      // Then according to dichotomy, shorten the interval of plaintext space and cipher text space.
      // By recursive call, find the cipher text value that corresponding plaintext value finally.
      const sampleResult: BigNumber = this.uniformSampleInBigNum(mid, bigNumSpace, key);

      // According to value and mid value,
      // shorten the interval of plaintext space and cipher text space by dichotomy.
      if (bigNumSpace.value.lte(mid)) {
        bigNumSpace.inSize = mid.minus(bigNumSpace.inEdge).plus(1);
        bigNumSpace.outSize = sampleResult.minus(bigNumSpace.outEdge).plus(1);
      } else {
        bigNumSpace.inSize = bigNumSpace.inSize.plus(bigNumSpace.inEdge).minus(1).minus(mid);
        bigNumSpace.outSize = bigNumSpace.outSize
          .plus(bigNumSpace.outEdge)
          .minus(1)
          .minus(sampleResult);
        bigNumSpace.inEdge = mid.plus(1);
        bigNumSpace.outEdge = sampleResult.plus(1);
      }
    }
    return opeValueByBigNum;
  }

  private uniformSampleInBigNum(
    value: BigNumber,
    bigNumSpace: BigNumSpace,
    // @ts-ignore
    key: CryptoJS.lib.WordArray
  ): BigNumber {
    const sampleSpace = BigNumSpace.copy(bigNumSpace);
    this.calculateSampleSpaceWithRedundancy(sampleSpace, value);
    if (sampleSpace.outSize.eq(1)) {
      return sampleSpace.outEdge;
    }

    const sampleCoin = this.calculateSampleCoinInBigNum(value, key);

    // uniformSample = sampleSpace.outEdge + sampleCoin % sampleSpace.outSize
    // Guarantee sample result between outEdge and outSize
    // The plaintext value corresponding to sampleResult in cipher text space.
    return sampleSpace.outEdge.plus(sampleCoin.mod(sampleSpace.outSize));
  }

  private calculateSampleSpaceWithRedundancy(sampleSpace: BigNumSpace, value: BigNumber): void {
    if (sampleSpace.inSize.eq(1)) {
      return;
    }
    const redundancySize: BigNumber = this.calculateRedundancySize(sampleSpace);

    if (redundancySize.gt(sampleSpace.outSize)) {
      // sampleSpace.outEdge = sampleSpace.outEdge + value - sampleSpace.inEdge
      sampleSpace.outEdge = sampleSpace.outEdge.plus(value).minus(sampleSpace.inEdge);
      // sample.outSize = sampleSpace.outSize + 1 - sampleSpace.inSize
      sampleSpace.outSize = sampleSpace.outSize.plus(1).minus(sampleSpace.inSize);
    } else {
      // sampleSpace.outSize = sampleSpace.outSize + 1 - redundancySize
      sampleSpace.outSize = sampleSpace.outSize.plus(1).minus(redundancySize);
      // sampleSpace.outEdge = sampleSpace.outEdge + (value - sampleSpace.inEdge) * SAMPLE_REDUNDANCY / 10
      let temp: BigNumber = value.minus(sampleSpace.inEdge);
      temp = temp.times(OpeGenerator.CIPHER_TEXT_SAMPLE_REDUNDANCY).dividedToIntegerBy(10);
      sampleSpace.outEdge = sampleSpace.outEdge.plus(temp);
    }
  }

  private calculateRedundancySize(sampleSpace: BigNumSpace): BigNumber {
    let redundancySize = sampleSpace.inSize;
    // redundancySize = redundancySize * CIPHER_TEXT_SAMPLE_REDUNDANCY / NUMBER_RADIX_DECIMAL
    redundancySize = redundancySize.times(OpeGenerator.CIPHER_TEXT_SAMPLE_REDUNDANCY);
    redundancySize = redundancySize.dividedToIntegerBy(OpeGenerator.NUMBER_RADIX_DECIMAL);

    return redundancySize;
  }

  // @ts-ignore
  private calculateSampleCoinInBigNum(value: BigNumber, key: CryptoJS.lib.WordArray): BigNumber {
    // change bigNum to hexadecimal string
    let plaintextStr: string = value.toString(16).toUpperCase();

    // According to C++，the length of plaintextStr should be even number. If not, add '0' in front.
    if (plaintextStr !== '0' && plaintextStr.length % 2 !== 0) {
      plaintextStr = '0' + plaintextStr;
    }

    // @ts-ignore
    const valueWA: CryptoJS.lib.WordArray = CryptoJS.enc.Utf8.parse(plaintextStr);
    // @ts-ignore
    const coinSeed: CryptoJS.lib.WordArray = valueWA.concat(key);

    // Taking ope key and mid value of plaintext space as coin seed, to calculate hash value by SHA256.
    // Then add hash value to the coin value by circulation in cipher text space,
    // coin length is determined by outSize.
    // In one word, the mid value in plaintext space, corresponding to the coin value in cipher text space.
    // @ts-ignore
    const shaResult: CryptoJS.lib.WordArray = CryptoJS.SHA256(coinSeed);

    return new BigNumber('0x' + this.changeOrder(shaResult.toString(CryptoJS.enc.Hex)));
  }

  private hex2binForUint64(hex: string): string {
    const rst: string = ('00000000' + parseInt(hex, 16).toString(2)).substr(-8);
    return rst.split('').reverse().join('');
  }

  private changeOrder(str: string): string {
    let index = str.length;
    let rst = '';
    while (index >= 0) {
      rst += str.substring(index - 2, index);
      index -= 2;
    }
    return rst;
  }

  private inputVerification(input: string, type: number) {
    if (type === OpeDataType.OPE_TYPE_NULL) {
      Logger.warn(TAG, 'generateOpeValue: ope type input is invalid, type: OPE_TYPE_NULL.');
      throw Error('generateOpeValue: ope type input is invalid, OPE_TYPE_NULL.');
    }

    if (type === OpeDataType.OPE_TYPE_BOOL) {
      if (input !== '1' && input !== '0') {
        Logger.warn(
          TAG,
          `generateOpeValue: boolean type input is invalid, input is not a boolean value.`
        );
        throw Error('generateOpeValue: boolean type input is invalid.');
      }
    }

    if (type !== OpeDataType.OPE_TYPE_STRING && type !== OpeDataType.OPE_TYPE_BOOL) {
      if (input === '' || input.trim() === '') {
        Logger.warn(TAG, `generateOpeValue: Number type input is invalid, input is empty.`);
        throw Error('generateOpeValue: Number type input is invalid.');
      }

      if (isNaN(Number(input))) {
        Logger.warn(TAG, `generateOpeValue: Number type input is invalid, input is NaN.`);
        throw Error('generateOpeValue: Number type input is invalid.');
      }
    }
  }
}
