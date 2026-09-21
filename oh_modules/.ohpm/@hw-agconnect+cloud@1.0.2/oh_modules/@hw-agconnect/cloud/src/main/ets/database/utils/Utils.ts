/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { DatabaseException } from '../DatabaseException';
import { ExceptionUtil } from './ExceptionUtil';
import { CloudDBCryptoJS } from '../encrypt/crypto/CloudDBCryptoJS';

const CANDIDATE_CHARS = 'abcdefghijklmnopqrstuvwxyz1234567890';

const CryptoJS = CloudDBCryptoJS.getCryptoJS();

export class Utils {
  private static readonly TRACE_ID_EXP = /^[0-9a-f]{1,32}$/;
  private static RANDOM_DIVISOR = 0xffffffff;
  private static RANDOM_VALUE = 0x10000;
  private static RANDOM_RANGE = 1000000000;
  private static HEX = 16;
  private static TRACE_ID_LENGTH = 32;
  private static RANDOM_KEY_LENGTH = 4;

  static isFunction(object: any) {
    return typeof object === 'function';
  }

  static isArray(value: any) {
    if (typeof Array.isArray === 'function') {
      return Array.isArray(value);
    } else {
      return Object.prototype.toString.call(value) === '[object Array]';
    }
  }

  static isObject(value: any) {
    return Object.prototype.toString.call(value) === '[object Object]';
  }

  static isNotNullObject(value: unknown) {
    return value !== null ? typeof value === 'object' : false;
  }

  static isNullOrUndefined(value: any) {
    return value === undefined || value === null;
  }

  static checkNotNull(value: unknown, message: string) {
    if (Utils.isNullOrUndefined(value)) {
      throw ExceptionUtil.build(message);
    }
  }

  static isClass(object: any) {
    if (Utils.isFunction(object)) {
      const prototype = object.prototype;
      if (!Utils.isNotNullObject(prototype)) {
        return false;
      }
      const constructor = prototype.constructor;
      if (Utils.isFunction(constructor)) {
        return true;
      }
    }
    return false;
  }

  static isErrorObject(object: any) {
    // The object is error message {message: message} or {code: code, message: message}
    if (
      object instanceof DatabaseException ||
      (Utils.isObject(object) &&
        Object.prototype.hasOwnProperty.call(object, 'message') &&
        Object.getOwnPropertyNames(object).length === 1)
    ) {
      return true;
    }
    return false;
  }

  static isArrayBuffer(object: any): boolean {
    if (!object) {
      return false;
    }
    const objectToString = Object.prototype.toString.call(object);
    return objectToString === '[object ArrayBuffer]' || objectToString === '[object Uint8Array]';
  }

  static isEmpty(...params: any) {
    if (params.length === 0) {
      return true;
    }
    for (const param of params) {
      if (!param) {
        return true;
      }
    }
    return false;
  }

  static isValidObject(objectList: any): boolean {
    if (!objectList || typeof objectList !== 'object' || objectList.constructor.name === 'Object') {
      return false;
    }
    return true;
  }

  static isSameObjectType(objectList: any) {
    Utils.checkNotNull(objectList, 'The object list is invalid.');
    if (Utils.isEmptyArray(objectList)) {
      return true;
    }
    const firstType = this.getClassName(objectList[0]);
    for (const object of objectList) {
      if (this.getClassName(object) !== firstType) {
        return false;
      }
    }
    return true;
  }

  static isEmptyArray(list: any[]) {
    return list.length === 0;
  }

  static getClassName(clz: any) {
    if (Utils.isNullOrUndefined(clz)) {
      return clz;
    }
    let input = clz;
    if (!Utils.isClass(input)) {
      input = clz.constructor;
    }
    return input.className ? input.className : input.name;
  }

  static deepCopy(objectList: any[]) {
    const list: any[] = [];
    for (const objectItem of objectList) {
      if (typeof objectItem !== 'object') {
        list.push(objectItem);
        continue;
      }
      if (objectItem.constructor === Date) {
        list.push(new Date(objectItem));
        continue;
      }
      if (objectItem.constructor === RegExp) {
        list.push(new RegExp(objectItem));
        continue;
      }
      if (objectItem.clone) {
        list.push(objectItem.clone());
        continue;
      }
      const newObj = new objectItem.constructor();
      for (const key in objectItem) {
        if (Object.prototype.hasOwnProperty.call(objectItem, key)) {
          const val = objectItem[key];
          newObj[key] = val;
        }
      }
      list.push(newObj);
    }
    return list;
  }

  static deepCopyNumber(values: Set<number>): Set<number> {
    const newSet: Set<number> = new Set();
    values.forEach(value => {
      newSet.add(value);
    });
    return newSet;
  }

  static hash(value: string | number) {
    const str = '' + value;
    let hash = 5381;
    let index = str.length;
    while (index) {
      hash = (hash * 33) ^ str.charCodeAt(--index);
    }
    return '' + (hash >>> 0);
  }

  static generateUUID(): string {
    const timestamp = new Date().getTime();
    let uuid = '';
    for (let index = 1; index < 15; index = index + 2) {
      const code = (timestamp >>> index) % 36;
      uuid = uuid + CANDIDATE_CHARS.charAt(code);
    }
    return uuid;
  }

  static generateTraceId(): string {
    let uuid = '';
    for (let i = 0; i < this.TRACE_ID_LENGTH / this.RANDOM_KEY_LENGTH; i++) {
      uuid += this.randomKey();
    }
    return uuid;
  }

  static randomKey(): string {
    return (((1 + this.getSecRandom()) * this.RANDOM_VALUE) | 0).toString(this.HEX).substring(1);
  }

  static getSecRandom(): number {
    return Math.floor(Math.random() * this.RANDOM_RANGE) / (this.RANDOM_DIVISOR + 1);
  }

  /**
   * Uint8Array to string
   * @param fileData Uint8Array
   */
  static uint8ArrayToString(fileData: Uint8Array): string {
    return decodeURIComponent(escape(String.fromCharCode(...fileData)));
  }

  /**
   * string to Uint8Array
   * @param str string
   */
  static stringToUint8Array(str: string): Uint8Array {
    // spilt('') Each character is divided between them
    const arr = unescape(encodeURIComponent(str))
      .split('')
      .map(val => val.charCodeAt(0));
    return new Uint8Array(arr);
  }

  /**
   * wordArray to Uint8Array.
   * @param wordArray wordArray
   */
  // @ts-ignore
  static wordArrayToUint8Array(wordArray: any): Uint8Array {
    const byteCount = wordArray.sigBytes;
    const words = wordArray.words;
    const result = new Uint8Array(byteCount);
    let i = 0; /*dst*/
    let j = 0; /*src*/
    while (true) {
      // here i is a multiple of 4
      if (i === byteCount) {
        break;
      }
      const word = words[j++];
      result[i++] = (word & 0xff000000) >>> 24;
      if (i === byteCount) {
        break;
      }
      result[i++] = (word & 0x00ff0000) >>> 16;
      if (i === byteCount) {
        break;
      }
      result[i++] = (word & 0x0000ff00) >>> 8;
      if (i === byteCount) {
        break;
      }
      result[i++] = word & 0x000000ff;
    }
    return result;
  }

  /**
   * uint8Array to wordArray
   * @param uint8Array uint8Array
   */
  // @ts-ignore
  static uint8ArrayToWordArray(uint8Array: Uint8Array): any {
    const len = uint8Array.length;
    // Convert
    const words: any = [];
    for (let i = 0; i < len; i++) {
      words[i >>> 2] |= (uint8Array[i] & 0xff) << (24 - (i % 4) * 8);
    }
    return CryptoJS.lib.WordArray.create(words, len);
  }

  /**
   * CryptoJS base64 encode
   * @param key wordArray
   */
  // @ts-ignore
  static encode(key: any): string {
    return CryptoJS.enc.Base64.stringify(key);
  }

  /**
   * CryptoJS base64 decode
   * @param key string
   */
  // @ts-ignore
  static decode(key: string): any {
    return CryptoJS.enc.Base64.parse(key);
  }

  static convertArray<T>(objectList: T[] | T): T[] {
    if (Utils.isArray(objectList)) {
      return objectList as T[];
    } else {
      return [objectList as T];
    }
  }

  static isStringEmpty(value: string) {
    return value === undefined || value === null || value === '';
  }

  static checkTraceId(traceId: string): boolean {
    return this.TRACE_ID_EXP.test(traceId);
  }
}
