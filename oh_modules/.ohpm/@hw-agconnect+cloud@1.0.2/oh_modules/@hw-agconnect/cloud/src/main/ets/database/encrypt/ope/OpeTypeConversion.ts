/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { BigNumSpace } from './Utils/BigNumSpace';
import { FloatPointParameter } from './Utils/FloatPointParameter';
import { OpeDataType } from './Utils/OpeDataType';
import { Uint64Space } from './Utils/Uint64Space';
// @ts-ignore
import Long from 'long';
import BigNumber from 'bignumber.js';

const TAG = 'OpeTypeConversion';

/**
 * This class is used to convert all type data to ope space
 */
export class OpeTypeConversion {
  private static readonly NUMBER_RADIX_DECIMAL = 10;
  private static readonly NUMBER_RADIX_DECIMAL_LOG2 = Math.log2(
    OpeTypeConversion.NUMBER_RADIX_DECIMAL
  );
  private static readonly INT8_DEFAULT_DIGIT = 8;
  private static readonly INT16_DEFAULT_DIGIT = 16;
  private static readonly INT32_DEFAULT_DIGIT = 32;
  private static readonly INT64_DEFAULT_DIGIT = 64;
  private static readonly INT8_NEGATIVE_EDGE = -7;
  private static readonly INT16_NEGATIVE_EDGE = -15;
  private static readonly INT32_NEGATIVE_EDGE = -31;
  private static readonly INT64_NEGATIVE_EDGE = -63;
  private static readonly FLOAT_DEFAULT_PRECISION = 8;
  // The max range of exponent in float value
  private static readonly FLOAT_EXPONENT_MAX_RANGE = 38;
  // The max length of exponent in float value
  private static readonly FLOAT_EXPONENT_MAX_LEN = 3;
  private static readonly DOUBLE_DEFAULT_PRECISION = 17;
  // The max range of exponent in double value
  private static readonly DOUBLE_EXPONENT_MAX_RANGE = 308;
  // The max length of exponent in double value
  private static readonly DOUBLE_EXPONENT_MAX_LEN = 4;
  // Need to add fixed redundancy for the plaintext
  private static readonly PLAIN_TEXT_REDUNDANCY = 8;
  private static readonly PLAIN_TEXT_REDUNDANCY_LOG2 = Math.log2(
    OpeTypeConversion.PLAIN_TEXT_REDUNDANCY
  );
  // The expansion rate of cipher text space
  private static readonly CIPHER_SPACE_RATE = 13000;
  private static readonly CIPHER_SPACE_RATE_BASE = 10000;
  // Need to set a lower bound of expansion to reduce the probability of weak keys
  private static readonly CIPHER_SPACE_LIMIT = 1024;
  private static readonly CIPHER_SPACE_LIMIT_LOG2 = Math.log2(OpeTypeConversion.CIPHER_SPACE_LIMIT);
  // Truncated byte length for string
  private static readonly STRING_VALID_BYTE_LEN = 16;
  // All ASCII character
  private static readonly CHAR_SPACE_SIZE = 256;
  // Number of valid digits in float
  private static readonly FLOAT_VALID_DIGITS = 7;
  // Number of valid digits in double
  private static readonly DOUBLE_VALID_DIGITS = 16;

  // ope fail
  public static readonly OPE_FAIL = -1;
  // ope success
  public static readonly OPE_SUCCESS = 1;

  public static convertToOpeDataSpaceUint64(
    input: string,
    type: number,
    uint64Space: Uint64Space
  ): number {
    if (input == null || uint64Space == null) {
      Logger.warn(TAG, 'convertToOpeDataSpaceUint64: input parameter is invalid');
      return this.OPE_FAIL;
    }
    switch (type) {
      case OpeDataType.OPE_TYPE_BOOL:
      case OpeDataType.OPE_TYPE_INT8:
        return this.convertInt8ToOpeDataSpace(input, uint64Space);
      case OpeDataType.OPE_TYPE_INT16:
        return this.convertInt16ToOpeDataSpace(input, uint64Space);
      case OpeDataType.OPE_TYPE_INT32:
        return this.convertInt32ToOpeDataSpace(input, uint64Space);
      case OpeDataType.OPE_TYPE_FLOAT:
        return this.convertFloatToOpeDataSpace(input, uint64Space);
      default:
        Logger.warn(
          TAG,
          'convertToOpeDataSpaceUint64: input type is error to Uint64Space, type: ' + type
        );
        return this.OPE_FAIL;
    }
  }

  public static convertToOpeDataSpaceBigNum(
    input: Uint8Array | string,
    inLen: number,
    type: number,
    bigNumSpace: BigNumSpace
  ): number {
    if (input == null || inLen == null || inLen <= 0) {
      Logger.warn(TAG, 'convertToOpeDataSpaceBigNum: input parameter is invalid.');
      return this.OPE_FAIL;
    }
    switch (type) {
      case OpeDataType.OPE_TYPE_INT64:
      case OpeDataType.OPE_TYPE_DATE:
        if (typeof input === 'string') {
          return this.convertInt64ToOpeDataSpace(input, bigNumSpace);
        }
        Logger.warn(
          TAG,
          'convertToOpeDataSpaceBigNum: input type should be string but got: .' + typeof input
        );
        return this.OPE_FAIL;
      case OpeDataType.OPE_TYPE_DOUBLE:
        if (typeof input === 'string') {
          return this.convertDoubleToOpeDataSpace(input, bigNumSpace);
        }
        Logger.warn(
          TAG,
          'convertToOpeDataSpaceBigNum: input type should be string but got: .' + typeof input
        );
        return this.OPE_FAIL;
      case OpeDataType.OPE_TYPE_STRING:
        if (typeof input !== 'string') {
          return this.convertStringToOpeDataSpace(input, inLen, bigNumSpace);
        }
        Logger.warn(
          TAG,
          'convertToOpeDataSpaceBigNum: input type should be Uint8Array but got: .' + typeof input
        );
        return this.OPE_FAIL;
      default:
        Logger.warn(
          TAG,
          'convertToOpeDataSpaceBigNum: input type is error to BigNumSpace, type: ' + type
        );
        return this.OPE_FAIL;
    }
  }

  private static convertInt8ToOpeDataSpace(input: string, uint64Space: Uint64Space): number {
    // convert input string to decimal signed long
    let plaintext: Long = Long.fromString(input, true, this.NUMBER_RADIX_DECIMAL);
    // increase plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.multiply(this.PLAIN_TEXT_REDUNDANCY);
    const maxDigitSize = this.INT8_DEFAULT_DIGIT + this.PLAIN_TEXT_REDUNDANCY_LOG2;
    const edge = this.INT8_NEGATIVE_EDGE - this.PLAIN_TEXT_REDUNDANCY_LOG2;
    return this.convertToUint64Space(plaintext, maxDigitSize, edge, uint64Space);
  }

  private static convertInt16ToOpeDataSpace(input: string, uint64Space: Uint64Space): number {
    // convert input string to decimal signed long
    let plaintext: Long = Long.fromString(input, true, this.NUMBER_RADIX_DECIMAL);
    // increase plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.multiply(this.PLAIN_TEXT_REDUNDANCY);
    const maxDigitSize = this.INT16_DEFAULT_DIGIT + this.PLAIN_TEXT_REDUNDANCY_LOG2;
    const edge = this.INT16_NEGATIVE_EDGE - this.PLAIN_TEXT_REDUNDANCY_LOG2;
    return this.convertToUint64Space(plaintext, maxDigitSize, edge, uint64Space);
  }

  private static convertInt32ToOpeDataSpace(input: string, uint64Space: Uint64Space): number {
    // convert input string to decimal signed long
    let plaintext: Long = Long.fromString(input, true, this.NUMBER_RADIX_DECIMAL);
    // increase plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.multiply(this.PLAIN_TEXT_REDUNDANCY);
    const maxDigitSize = this.INT32_DEFAULT_DIGIT + this.PLAIN_TEXT_REDUNDANCY_LOG2;
    const edge = this.INT32_NEGATIVE_EDGE - this.PLAIN_TEXT_REDUNDANCY_LOG2;
    return this.convertToUint64Space(plaintext, maxDigitSize, edge, uint64Space);
  }

  private static convertInt64ToOpeDataSpace(input: string, bigNumSpace: BigNumSpace): number {
    let plaintext = new BigNumber(input);

    // increase plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.times(this.PLAIN_TEXT_REDUNDANCY);
    const maxDigitSize = this.INT64_DEFAULT_DIGIT + this.PLAIN_TEXT_REDUNDANCY_LOG2;
    const edge = this.INT64_NEGATIVE_EDGE - this.PLAIN_TEXT_REDUNDANCY_LOG2;
    return this.convertToBigNumSpace(plaintext, maxDigitSize, edge, bigNumSpace);
  }

  private static convertFloatToOpeDataSpace(input: string, uint64Space: Uint64Space): number {
    const value = parseFloat(input);
    const textFormat = value.toExponential(this.FLOAT_VALID_DIGITS);
    // According to the fixed format, convert float value to uint64 value.
    let plaintext: Long = this.convertFloatToUint64(
      textFormat,
      textFormat.length + 1,
      this.FLOAT_EXPONENT_MAX_RANGE,
      this.FLOAT_DEFAULT_PRECISION
    );

    // Increasing plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.multiply(this.PLAIN_TEXT_REDUNDANCY);
    let maxDigitSize =
      (this.FLOAT_DEFAULT_PRECISION + this.FLOAT_EXPONENT_MAX_LEN) *
        this.NUMBER_RADIX_DECIMAL_LOG2 +
      this.PLAIN_TEXT_REDUNDANCY_LOG2 -
      1;
    maxDigitSize = Math.floor(maxDigitSize);
    const edge = 0;
    return this.convertToUint64Space(plaintext, maxDigitSize, edge, uint64Space);
  }

  private static convertDoubleToOpeDataSpace(input: string, bigNumSpace: BigNumSpace): number {
    const value = parseFloat(input);
    const textFormat = value.toExponential(this.DOUBLE_VALID_DIGITS);
    // According to the fixed format, convert double value to bigint value.
    let plaintext: BigNumber = this.convertDoubleToBigNum(
      textFormat,
      textFormat.length + 1,
      this.DOUBLE_EXPONENT_MAX_RANGE,
      this.DOUBLE_DEFAULT_PRECISION
    );
    // Increasing plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.times(this.PLAIN_TEXT_REDUNDANCY);
    let maxDigitSize =
      (this.DOUBLE_DEFAULT_PRECISION + this.DOUBLE_EXPONENT_MAX_LEN) *
        this.NUMBER_RADIX_DECIMAL_LOG2 +
      this.PLAIN_TEXT_REDUNDANCY_LOG2 -
      1;
    maxDigitSize = Math.floor(maxDigitSize);
    const edge = 0;
    return this.convertToBigNumSpace(plaintext, maxDigitSize, edge, bigNumSpace);
  }

  private static convertStringToOpeDataSpace(
    input: Uint8Array,
    inLen: number,
    bigNumSpace: BigNumSpace
  ): number {
    // According to the fixed format, convert string to bigint value.
    let plaintext: BigNumber = this.convertCharToBigNum(input, inLen, this.STRING_VALID_BYTE_LEN);
    // Increasing plaintext space, reduce collision that plaintext map to cipher text.
    plaintext = plaintext.times(this.PLAIN_TEXT_REDUNDANCY);
    const maxDigitSize =
      this.STRING_VALID_BYTE_LEN * Math.log2(this.CHAR_SPACE_SIZE) +
      this.PLAIN_TEXT_REDUNDANCY_LOG2 +
      1;
    const edge = 0;
    return this.convertToBigNumSpace(plaintext, maxDigitSize, edge, bigNumSpace);
  }

  private static convertFloatToUint64(
    text: string,
    textLen: number,
    maxExpRange: number,
    maxPrecision: number
  ): Long {
    if (text == null || textLen <= 0) {
      Logger.warn(TAG, 'convertFloatToUint64: text is null');
      throw Error('convertFloatToUint64: text is null');
    }
    // convert float value to structure that format is FloatingPointParameter
    const floatPointParameter = new FloatPointParameter();
    this.calculateFloatingPointParameter(text, textLen, floatPointParameter);
    this.calculateNormalizedExp(text, maxExpRange, floatPointParameter);
    const formatTextLen: number = floatPointParameter.expLen + maxPrecision;

    // convert floatPointParameter to string, finally convert to uint64
    const formatText: string = this.translateFloatingPointToChar(
      text,
      maxPrecision,
      floatPointParameter,
      formatTextLen
    );
    return Long.fromString(formatText);
  }

  private static convertDoubleToBigNum(
    text: string,
    textLen: number,
    maxExpRange: number,
    maxPrecision: number
  ): BigNumber {
    if (text == null || textLen <= 0) {
      Logger.warn(TAG, 'convertDoubleToBigNum: text is null');
      throw Error('convertDoubleToBigNum: text is null');
    }
    // convert double value to structure that format is FloatingPointParameter
    const floatPointParameter = new FloatPointParameter();
    this.calculateFloatingPointParameter(text, textLen, floatPointParameter);
    this.calculateNormalizedExp(text, maxExpRange, floatPointParameter);
    const formatTextLen: number = floatPointParameter.expLen + maxPrecision;

    // convert floatPointParameter to string, finally convert to bigNum
    const formatText: string = this.translateFloatingPointToChar(
      text,
      maxPrecision,
      floatPointParameter,
      formatTextLen
    );
    return new BigNumber(formatText);
  }

  private static convertCharToBigNum(
    uint8Array: Uint8Array,
    textLen: number,
    maxLen: number
  ): BigNumber {
    let plaintext: BigNumber = new BigNumber(0);
    let radix: BigNumber = new BigNumber(1);
    let current: BigNumber;
    if (textLen >= maxLen) {
      plaintext = new BigNumber(uint8Array[maxLen - 1]);
    }
    // plaintext += CHAR_SPACE_SIZE^(maxLen - i) * text[i]
    for (let i = maxLen - 1; i > 0; i--) {
      radix = radix.times(this.CHAR_SPACE_SIZE);
      if (textLen >= i) {
        current = radix;
        current = current.times(uint8Array[i - 1] === undefined ? 0 : uint8Array[i - 1]);
        plaintext = plaintext.plus(current);
      }
    }
    return plaintext;
  }

  private static calculateFloatingPointParameter(
    text: string,
    textLen: number,
    floatPointParameter: FloatPointParameter
  ): void {
    // Parse text of floating point, such as 1.23456e+2, calculate parameter is
    // radixSign = 0, radixLen = 7, expSign = 0, expLen = 1, effectiveLen = 10
    let pos = 0;
    if (text.charAt(pos) === '-') {
      floatPointParameter.radixSign = 1;
    }
    while (text.charAt(pos) !== 'e') {
      pos++;
    }

    // calculate
    floatPointParameter.radixLen = pos;
    if (text.charAt(pos + 1) === '-') {
      floatPointParameter.expSign = 1;
    }
    pos += 2;
    while (text.charAt(pos) === '0') {
      pos++;
    }

    while (pos < textLen) {
      if (text.charCodeAt(pos) >= '0'.charCodeAt(0) && text.charCodeAt(pos) <= '9'.charCodeAt(0)) {
        pos++;
        floatPointParameter.expLen++;
      } else {
        break;
      }
    }

    floatPointParameter.effectiveLen = pos;
    floatPointParameter.expLen = floatPointParameter.expLen === 0 ? 1 : floatPointParameter.expLen;
  }

  private static calculateNormalizedExp(
    text: string,
    maxExpRange: number,
    floatPointParameter: FloatPointParameter
  ): void {
    // Parse text of floating point, such as 1.23456e+2, calculate parameter is radixSign = 0, radixLen = 7,
    // expSign = 0, expLen = 3, effectiveLen = 10, normalizedSize = 100, normalizedExp = 116
    let size = floatPointParameter.normalizedSize;
    let exp: number;
    if (text.charAt(0) === '0') {
      exp = 2 * maxExpRange + 1;
      size *= this.NUMBER_RADIX_DECIMAL;
    } else if (floatPointParameter.radixSign === 1) {
      exp = maxExpRange;
      for (let i = 0; i < floatPointParameter.expLen; i++) {
        if (floatPointParameter.expSign === 1) {
          exp +=
            (text.charCodeAt(floatPointParameter.effectiveLen - 1 - i) - '0'.charCodeAt(0)) * size;
        } else {
          exp -=
            (text.charCodeAt(floatPointParameter.effectiveLen - 1 - i) - '0'.charCodeAt(0)) * size;
        }
        size *= this.NUMBER_RADIX_DECIMAL;
      }
    } else {
      exp = 3 * maxExpRange + 1;
      for (let i = 0; i < floatPointParameter.expLen; i++) {
        if (floatPointParameter.expSign === 1) {
          exp -=
            (text.charCodeAt(floatPointParameter.effectiveLen - 1 - i) - '0'.charCodeAt(0)) * size;
        } else {
          exp +=
            (text.charCodeAt(floatPointParameter.effectiveLen - 1 - i) - '0'.charCodeAt(0)) * size;
        }
        size *= this.NUMBER_RADIX_DECIMAL;
      }
    }

    if (parseInt((exp / size).toString(10), 10) === 0) {
      size = Math.floor(size / this.NUMBER_RADIX_DECIMAL);
      while (parseInt((exp / size).toString(10), 10) === 0) {
        if (size === 1) {
          floatPointParameter.expLen--;
          break;
        }
        size = Math.floor(size / this.NUMBER_RADIX_DECIMAL);
        floatPointParameter.expLen--;
      }
    } else {
      while (parseInt((exp / size).toString(10), 10) !== 0) {
        size *= this.NUMBER_RADIX_DECIMAL;
        floatPointParameter.expLen++;
      }
      size = Math.floor(size / this.NUMBER_RADIX_DECIMAL);
    }

    floatPointParameter.normalizedSize = size;
    floatPointParameter.normalizedExp = exp;
  }

  private static translateFloatingPointToChar(
    text: string,
    maxPrecision: number,
    floatPointParameter: FloatPointParameter,
    formatTextLen: number
  ): string {
    if (formatTextLen < floatPointParameter.expLen + maxPrecision) {
      Logger.warn(TAG, 'translateFloatingPointToChar: formatText length is not enough.');
      throw Error('translateFloatingPointToChar: formatText length is not enough.');
    }
    // Parse text of floating point, such as 1.23456e+2, calculate parameter is radixSign = 0, radixLen = 7,
    // expSign = 0, expLen = 3, effectiveLen = 10, normalizedSize = 100, normalizedExp = 116
    // calculate formatText = "1161234560"
    const charCodes: number[] = [];
    for (let i = 0; i < floatPointParameter.expLen; i++) {
      // charCodes[i] = '0'.charCodeAt(0) + floatPointParameter.normalizedExp / floatPointParameter.normalizedSize
      charCodes[i] =
        '0'.charCodeAt(0) +
        Math.floor(floatPointParameter.normalizedExp / floatPointParameter.normalizedSize);
      floatPointParameter.normalizedExp %= floatPointParameter.normalizedSize;
      // floatPointParameter.normalizedSize = floatPointParameter.normalizedSize / this.NUMBER_RADIX_DECIMAL
      floatPointParameter.normalizedSize = Math.floor(
        floatPointParameter.normalizedSize / this.NUMBER_RADIX_DECIMAL
      );
    }

    let len = 0;
    let precision = 0;
    if (floatPointParameter.radixSign === 1) {
      len++;
      while (precision < maxPrecision) {
        if (len >= floatPointParameter.radixLen) {
          charCodes[precision + floatPointParameter.expLen] = '0'.charCodeAt(0);
          precision++;
          continue;
        }
        if (text.charAt(len) !== '.') {
          charCodes[precision + floatPointParameter.expLen] =
            '0'.charCodeAt(0) + 9 - text.charCodeAt(len) + '0'.charCodeAt(0);
          precision++;
        }
        len++;
      }
    } else {
      while (precision < maxPrecision) {
        if (len >= floatPointParameter.radixLen) {
          charCodes[precision + floatPointParameter.expLen] = '0'.charCodeAt(0);
          precision++;
          continue;
        }
        if (text.charAt(len) !== '.') {
          charCodes[precision + floatPointParameter.expLen] = text.charCodeAt(len);
          precision++;
        }
        len++;
      }
    }
    return String.fromCharCode(...charCodes);
  }

  private static convertToUint64Space(
    plaintext: Long,
    size: number,
    edge: number,
    uint64Space: Uint64Space
  ): number {
    // According to the plaintext space size, increase cipher text space size with the fixed rate.
    let outSize = Math.floor((size * this.CIPHER_SPACE_RATE) / this.CIPHER_SPACE_RATE_BASE);
    if (outSize - size < this.CIPHER_SPACE_LIMIT_LOG2) {
      outSize = size + this.CIPHER_SPACE_LIMIT_LOG2;
    }
    // Calculate plaintext space range and cipher text space range.
    uint64Space.inSize = Long.fromNumber(Math.pow(2, size), true);
    if (edge < 0) {
      uint64Space.inEdge = Long.MAX_UNSIGNED_VALUE.divide(2)
        .add(1)
        .subtract(Long.fromNumber(Math.pow(2, -edge), true));
    } else if (edge === 0) {
      uint64Space.inEdge = Long.UZERO;
    } else {
      uint64Space.inEdge = Long.fromNumber(Math.pow(2, edge), true);
    }

    uint64Space.outEdge = Long.UONE;
    if (outSize >= this.INT64_DEFAULT_DIGIT) {
      uint64Space.outSize = Long.MAX_UNSIGNED_VALUE;
      uint64Space.outLen = 16;
    } else {
      uint64Space.outSize = Long.fromNumber(Math.pow(2, outSize));
      uint64Space.outLen = Math.floor((outSize - 1) / 4) + 1;
      if (uint64Space.outLen % 2 !== 0) {
        uint64Space.outLen++;
      }
    }

    // Calculate corresponding plaintext value in plaintext space
    if (edge < 0) {
      if (plaintext.greaterThan(Long.MAX_UNSIGNED_VALUE.divide(2))) {
        uint64Space.value = plaintext
          .subtract(Long.MAX_UNSIGNED_VALUE.divide(2))
          .subtract(1)
          .toUnsigned();
      } else {
        uint64Space.value = plaintext.add(Long.MAX_UNSIGNED_VALUE.divide(2)).add(1).toUnsigned();
      }
    } else {
      uint64Space.value = plaintext;
    }

    return this.OPE_SUCCESS;
  }

  private static convertToBigNumSpace(
    plaintext: BigNumber,
    size: number,
    edge: number,
    bigNumSpace: BigNumSpace,
    outSize?: number
  ): number {
    if (outSize == null) {
      return this.convertToBigNumSpaceWithoutOutSize(plaintext, size, edge, bigNumSpace);
    }

    bigNumSpace.outEdge = new BigNumber(1);
    bigNumSpace.value = plaintext;

    // calculate plaintext space range and cipher text space range
    if (edge <= 0) {
      bigNumSpace.inEdge = new BigNumber(0);
      bigNumSpace.value = this.setBitLenToOneInBigNum(bigNumSpace.value, -edge);
    } else {
      bigNumSpace.inEdge = new BigNumber(2).pow(edge);
    }
    bigNumSpace.inSize = new BigNumber(2).pow(size);
    bigNumSpace.outSize = new BigNumber(2).pow(outSize);
    bigNumSpace.outLen = Math.floor((outSize - 1) / 4) + 1;
    if (bigNumSpace.outLen % 2 !== 0) {
      bigNumSpace.outLen++;
    }
    return this.OPE_SUCCESS;
  }

  private static convertToBigNumSpaceWithoutOutSize(
    plaintext: BigNumber,
    size: number,
    edge: number,
    bigNumSpace: BigNumSpace
  ): number {
    if (plaintext == null) {
      Logger.warn(TAG, 'convertToBigNumSpace: plaintext is null.');
      throw Error('convertToBigNumSpace: plaintext is null.');
    }
    bigNumSpace.inEdge = new BigNumber(0);
    bigNumSpace.inSize = new BigNumber(0);
    bigNumSpace.outEdge = new BigNumber(0);
    bigNumSpace.outSize = new BigNumber(0);
    // According to plaintext space size, increase cipher text space size with the fixed rate.
    let outSize = Math.floor((size * this.CIPHER_SPACE_RATE) / this.CIPHER_SPACE_RATE_BASE);
    if (outSize - size < this.CIPHER_SPACE_LIMIT_LOG2) {
      outSize = size + this.CIPHER_SPACE_LIMIT_LOG2;
    }
    return this.convertToBigNumSpace(plaintext, size, edge, bigNumSpace, outSize);
  }

  private static setBitLenToOneInBigNum(value: BigNumber, bitLen: number): BigNumber {
    if (bitLen <= 0) {
      return value;
    }
    const bigNumTemp = new BigNumber(2).pow(bitLen);
    return value.plus(bigNumTemp);
  }
}
