// @keepTs
// @ts-nocheck
import { Auth, AuthUser, CredentialInfo, GRS_TYPE, SignInParam, SignInResult, Token, VerifyCodeParam, VerifyCodeResult } from "./f";
import { UserManager } from "./k/l";
import common from "@ohos.app.ability.common";
import cloudCommon from "@hms.core.deviceCloudGateway.cloudCommon";
export declare class AuthImpl implements Auth {
    private static instance;
    userManager: UserManager | undefined;
    region: string | undefined;
    appContext: common.Context | undefined;
    json: object | string | undefined;
    private authBackend;
    private clientSecret;
    private clientId;
    private decryptMark;
    static getInstance(): AuthImpl;
    static getAuthInstance(): Auth;
    getAuthProvider(): cloudCommon.AuthProvider;
    requestVerifyCode(verifyCodeParam: VerifyCodeParam): Promise<VerifyCodeResult>;
    createUser(credentialInfo: CredentialInfo): Promise<SignInResult>;
    resetPassword(credentialInfo: CredentialInfo): Promise<void>;
    signIn(param: SignInParam): Promise<SignInResult>;
    signInAnonymously(): Promise<SignInResult>;
    deleteUser(): Promise<void>;
    signOut(): Promise<void>;
    getCurrentUser(): Promise<AuthUser | null>;
    init(applicationContext: Context, json: string): void;
    setRegion(region: string): Promise<void>;
    getGrsConfig(type: GRS_TYPE, region?: string): string;
    getProductId(): string;
    getAppId(): string;
    getClientId(): string;
    setClientSecret(clientSecret: string): void;
    setClientId(clientId: string): void;
    getClientSecret(): Promise<string>;
    getToken(refresh?: boolean, region?: string): Promise<Token>;
    getRegion(): string;
    private convertToUserInfo;
    private getDefaultRegion;
    private getString;
    private getDecryptString;
}
declare const _default: Auth;
export default _default;
