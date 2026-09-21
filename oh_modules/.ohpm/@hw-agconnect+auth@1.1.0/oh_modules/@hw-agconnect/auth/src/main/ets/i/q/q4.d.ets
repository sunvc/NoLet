// @keepTs
// @ts-nocheck
import { AuthUserExtra } from "../../f";
import { BaseResponse } from "../../h1/i1/w2/z2";
export interface Ret {
    code: number;
    msg: string;
}
export interface NetUserMetaData {
    createTime: string;
    lastSignInTime: string;
}
export interface UserExtraObject {
    ret: Ret;
    userMetaData: NetUserMetaData;
    emailVerified: number;
    passwordSetted: number;
    email: string;
    phone: string;
    displayName: string;
    photoUrl: string;
}
export declare class UserExtraResponse extends BaseResponse {
    displayName: string;
    photoUrl: string;
    emailVerified: number;
    passwordSetted: number;
    email: string;
    phone: string;
    userExtra: UserExtra;
    userMetaData: UserMetaData;
    /**
     * 构造方法，给定一些默认值，需要改变时，通过set方法设置
     */
    constructor();
    constructResponse(response: object): boolean;
}
export declare class UserExtra implements AuthUserExtra {
    createTime: string;
    lastSignInTime: string;
    getCreateTime(): string;
    getLastSignInTime(): string;
}
export declare class UserMetaData {
    createTime: string;
    lastSignInTime: string;
}
