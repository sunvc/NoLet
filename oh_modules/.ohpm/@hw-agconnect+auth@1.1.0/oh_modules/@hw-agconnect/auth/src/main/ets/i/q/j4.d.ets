// @keepTs
// @ts-nocheck
import { BaseResponse } from "../../h1/i1/w2/z2";
import { TokenInfo } from "../../s/o3";
export interface AccessToken {
    token: string;
    validPeriod: number;
}
export interface RefreshTokenObject {
    productId: string;
    accessToken: AccessToken;
    uid: string;
}
export declare class RefreshTokenResponse extends BaseResponse {
    accessToken: TokenInfo;
    productId: string;
    uid: string;
    constructResponse(response: object): boolean;
}
