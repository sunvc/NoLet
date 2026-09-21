// @keepTs
// @ts-nocheck
import { BaseResponse } from "../../h1/i1/w2/z2";
import { UserInfo } from "../../s/p3";
export interface ProviderUserInfo {
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
export interface UserLinkObject {
    providerUserInfo: ProviderUserInfo;
}
export declare class UserLinkResponse extends BaseResponse {
    private providerUserInfo;
    constructor();
    getProviderUserInfo(): UserInfo | undefined;
    setProviderUserInfo(providerUserInfo: UserInfo): void;
    constructResponse(response: object): boolean;
}
