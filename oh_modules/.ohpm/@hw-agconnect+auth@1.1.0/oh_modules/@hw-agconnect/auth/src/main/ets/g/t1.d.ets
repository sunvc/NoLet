// @keepTs
// @ts-nocheck
export declare class AGCAuthErrorCode {
    static readonly NULL_TOKEN: AuthErrorCode;
    static readonly NOT_SIGN_IN: AuthErrorCode;
    static readonly USER_LINK_FAILED: AuthErrorCode;
    static readonly USER_UNLINK_FAILED: AuthErrorCode;
    static readonly ALREADY_SIGN_IN_USER: AuthErrorCode;
    static readonly FAIL_TO_GET_ACCESS_TOKEN: AuthErrorCode;
    static readonly FAIL_TO_UPDATE_PROFILE: AuthErrorCode;
    static readonly FAIL_TO_UPDATE_EMAIL: AuthErrorCode;
    static readonly CREDENTIAL_INVALID: AuthErrorCode;
}
export interface AuthErrorCode {
    code: number;
    message: string;
}
