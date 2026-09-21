// @keepTs
// @ts-nocheck
export declare class AegisAes {
    static buildKey(c1: string, d1: string, e1: string, f1: string, iterationCount: number): Promise<string>;
    static decryptWithIv(u: string, a1: string, b1: string): Promise<string>;
    static encryptWithIv(m: string, o: string, t: string): Promise<string>;
    static uint8ArrayToHexStr(data: Uint8Array): string;
}
