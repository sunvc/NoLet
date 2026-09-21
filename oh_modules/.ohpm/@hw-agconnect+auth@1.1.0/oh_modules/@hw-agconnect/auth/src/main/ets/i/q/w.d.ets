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
export interface NetUserInfo {
    uid: string;
    displayName: string;
    photoUrl: string;
    phone: string;
    email: string;
    provider: number;
    openId: string;
    emailVerified: number;
    passwordSetted: number;
}
export interface Provider {
    uid: string;
    provider: number;
    email: string;
    phone: string;
}
export interface SignInObject {
    accessToken: AccessToken;
    refreshToken: RefreshToken;
    userInfo: NetUserInfo;
    providers: Provider[];
}
export declare class SignInResponse extends BaseResponse {
    private accessToken;
    private refreshToken;
    private userInfo;
    private providers;
    constructResponse(response: object): boolean;
    getAccessToken(): TokenInfo;
    setAccessToken(accessToken: TokenInfo): void;
    getRefreshToken(): TokenInfo;
    setRefreshToken(refreshToken: TokenInfo): void;
    getUserInfo(): UserInfo;
    getProviders(): Array<Map<string, string>>;
    private userInfoToMap;
}
