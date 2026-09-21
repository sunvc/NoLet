// @keepTs
// @ts-nocheck
export declare class FrameworkCrypto {
    static ohGenAesCbcEncryptWithIv(plain: string, q1: string, iv: string): Promise<string>;
    static ohGenAesCbcDecryptWithIv(plain: string, i1: string, iv: string): Promise<string>;
}
