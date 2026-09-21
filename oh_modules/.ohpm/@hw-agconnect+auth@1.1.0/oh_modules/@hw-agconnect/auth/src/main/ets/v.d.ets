// @keepTs
// @ts-nocheck
export declare enum AGConnectAuthCredentialProvider {
    Anonymous = 0,
    HMS_Provider = 1,
    SelfBuild_Provider = 10,
    Phone_Provider = 11,
    Email_Provider = 12
}
export interface EmailUser {
    email: string;
    password: string;
    verifyCode: string;
}
export interface PhoneUser {
    countryCode: string;
    phoneNumber: string;
    password: string;
    verifyCode: string;
    getPhone: () => string;
}
export interface AGConnectAuthCredential {
    /**
     * 获取提当前凭证的供者
     * @return 返回当前凭证的提供者
     */
    getProvider(): number;
}
