// @keepTs
// @ts-nocheck
import { BaseResponse } from "../../h1/i1/w2/z2";
export interface VerifyCodeObject {
    shortestInterval: string;
    validityPeriod: string;
}
export declare class VerifyCodeResponse extends BaseResponse {
    shortestInterval: string;
    validityPeriod: string;
    constructResponse(response: object): boolean;
}
