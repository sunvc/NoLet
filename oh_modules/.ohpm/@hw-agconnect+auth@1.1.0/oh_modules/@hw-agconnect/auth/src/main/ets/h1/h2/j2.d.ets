// @keepTs
// @ts-nocheck
export declare class Uint8ArrayUtil {
    /**
     * 16进制的HEX字符串转成Uint8Array
     * @param hexString hex string
     * @returns Uint8Array
     */
    static hexStringToUint8Array(n2: string): Uint8Array;
    /**
     * Uint8Array转成 hexstring
     * @param array
     * @returns
     */
    static uint8ArrayTohexString(array: Uint8Array): string;
    /**
     * uint8Array转普通字符串
     *
     * @param array uint8Array
     * @returns string
     */
    static uint8ArrayToString(array: Uint8Array): string;
    /**
     * 普通的字符串转成字节流
     *
     * @param str
     * @returns
     */
    static stringToUint8Array(str: string): Uint8Array;
    /**
     * Convert a hex string to a byte array
     */
    static bytesToHex(bytes: Int8Array | Uint8Array): string;
    /**
     * Convert a hex string to a byte array
     */
    static hexToBytes(j2: string): Int8Array;
}
