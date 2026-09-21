// @keepTs
// @ts-nocheck
interface b2 {
    unicode?: number;
    ok: boolean;
}
export declare class BufferEncoder {
    buffer: number[];
    private readOffset;
    constructor();
    pushUint8(value: number): void;
    pushUnicodeWithUtf8(value: number): void;
    parseUnicodeFromUtf16(h2: number, i2: number): b2;
    pushStringWithUtf8(value: string): number;
    toUint8Array(len?: number): Uint8Array;
}
export {};
