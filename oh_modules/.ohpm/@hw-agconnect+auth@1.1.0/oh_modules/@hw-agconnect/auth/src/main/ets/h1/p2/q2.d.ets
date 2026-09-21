// @keepTs
// @ts-nocheck
export declare class AGCError extends Error {
    code: number;
    message: string;
    constructor(code: number, message: string);
}
