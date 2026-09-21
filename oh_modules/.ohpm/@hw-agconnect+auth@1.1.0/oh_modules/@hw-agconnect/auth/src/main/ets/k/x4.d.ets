// @keepTs
// @ts-nocheck
import { AuthUser, AuthUserExtra, CredentialInfo, EmailInfo, PasswordInfo, PhoneInfo, ProviderType, SignInParam, SignInResult, TokenResult, UserProfileInfo } from "../f";
import { ReauthenticateResponse } from "../i/q/i4";
import { UserRawData } from "./q1";
import { AuthBackend } from "../i/j";
import { Interceptor } from "../h1/i1/j1/k1";
import { UserStored } from "../r1/s1";
export declare class AuthDefaultUser implements AuthUser {
    anonymous: boolean;
    uid: string;
    displayName: string;
    photoUrl: string;
    email: string;
    phone: string;
    providerId: string;
    emailVerified: number;
    passwordSetted: number;
    providerService: o5;
    tokenService: n5;
    storeManager: UserStored | undefined;
    authBackend: AuthBackend | undefined;
    static fromRawData(info: UserRawData): AuthDefaultUser;
    setStoreManager(o7: UserStored): void;
    setAuthBackend(n7: AuthBackend): void;
    toRawData(): UserRawData;
    getUid(): string;
    getEmail(): string;
    getPhone(): string;
    getDisplayName(): string;
    getPhotoUrl(): string;
    getProviderId(): string;
    isAnonymous(): boolean;
    getProviderInfo(): Map<string, string>[];
    getToken(forceRefresh: boolean): Promise<TokenResult>;
    getUserExtra(): Promise<AuthUserExtra>;
    getAccessToken(): string;
    getRefreshToken(): string;
    getEmailVerified(): boolean;
    getPasswordSetted(): boolean;
    updateProfile(userProfile: UserProfileInfo): Promise<void>;
    userReauthenticate(param: SignInParam): Promise<SignInResult>;
    reConfigUserFrom(response: ReauthenticateResponse): void;
    link(credentialInfo: CredentialInfo): Promise<SignInResult>;
    unlink(type: ProviderType): Promise<SignInResult>;
    updateEmail(f6: EmailInfo): Promise<void>;
    updatePhone(b6: PhoneInfo): Promise<void>;
    updatePassword(y5: PasswordInfo): Promise<void>;
    dispose(): Promise<void>;
    syncToStorage(): Promise<void>;
    createTokenInterceptor(): Interceptor;
    private updateAnonymousUserInfo;
    private userInfoToMap;
    private convertProvider;
}
declare class n5 {
    accessToken: string;
    accessTokenValidPeriod: number;
    refreshToken: string;
    v7: number;
    startTime: number;
    private readonly w7;
    getAccessToken(): string;
    getRefreshToken(): string;
    p7(): boolean;
    q7(): TokenResult;
    r7(): Promise<void>;
}
declare class o5 {
    providerInfo: Array<Map<string, string>>;
    s7(info: Map<string, string>): void;
    x7(provider: number, key: string, value: string): void;
    updateEmail(r5: string): void;
    updatePhone(q5: string): void;
    t7(provider: string): void;
    u7(provider: string): number | undefined;
}
export {};
