// @keepTs
// @ts-nocheck
export declare class DecryptExclamationMark {
    private static PATTERN_ENCRYPT;
    private static ITERATION_COUNT;
    private static IV_LENGTH;
    private aesKey;
    private rxHex;
    private ryHex;
    private rzHex;
    private slHex;
    constructor(rxHex: string, ryHex: string, rzHex: string, slHex: string);
    static isMatch(cipher: string): boolean;
    decrypt(raw: string): Promise<string>;
    isKeyValid(): boolean;
    getRawString(raw: string): string;
}
