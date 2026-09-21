import buffer from '@ohos.buffer';
import util from '@ohos.util';
import { Logger } from '../log/Logger'
import { BufferEncoder } from './BufferEncoder'

/**
 * 16进制的HEX字符串转成Uint8Array
 * @param hexString hex string
 * @returns Uint8Array
 */
export function hexStringToUint8Array(hexString: string): Uint8Array {
  return Uint8Array.from(hexString.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
}

/**
 * Uint8Array转成 hexstring
 * @param array
 * @returns
 */
export function uint8ArrayTohexString(array: Uint8Array): string {
  return buffer.from(array).toString('hex');
}

/**
 * uint8Array转普通字符串
 *
 * @param array uint8Array
 * @returns string
 */
export function uint8ArrayToString(array: Uint8Array): string {
  return buffer.from(array).toString('utf8');
}

/**
 * 普通的字符串转成字节流
 *
 * @param str
 * @returns
 */
export function stringToUint8Array(str: string): Uint8Array {
  try {
    return new util.TextEncoder('utf-8').encodeInto(str);
  } catch (e) {
    Logger.error("stringToUint8Array", 'TextEncoder error');
    let bufferEncoder = new BufferEncoder();
    bufferEncoder.pushStringWithUtf8(str);
    return bufferEncoder.toUint8Array();
  }

}
