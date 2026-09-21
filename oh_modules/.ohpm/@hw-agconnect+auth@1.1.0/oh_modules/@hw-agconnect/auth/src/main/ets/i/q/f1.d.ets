// @keepTs
// @ts-nocheck
import { BaseResponse } from "../../h1/i1/w2/z2";
import { TokenInfo } from "../../s/o3";
import { UserInfo } from "../../s/p3";
export interface AccessToken {
    token: string;
    validPeriod: number;
}
export interface RefreshToken {
    token: string;
    validPeriod: number;
}
export interface AnonymousObject {
    accessToken: AccessToken;
    refreshToken: RefreshToken;
    uid: string;
}
export declare class SignInAnonymousResponse extends BaseResponse {
    uid: string;
    private accessToken;
    private refreshToken;
    private userInfo;
    constructResponse(response: object): boolean;
    getAccessToken(): TokenInfo;
    setAccessToken(accessToken: TokenInfo): void;
    getRefreshToken(): TokenInfo;
    setRefreshToken(refreshToken: TokenInfo): void;
    getUserInfo(): UserInfo;
}
