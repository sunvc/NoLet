export class AGCAuthErrorCode {
  static readonly NULL_TOKEN: AuthErrorCode = { code: 1210001, message: 'token is null.' };
  static readonly NOT_SIGN_IN: AuthErrorCode = { code: 1210002, message: 'no user signed in.' };
  static readonly USER_LINK_FAILED: AuthErrorCode = {
    code: 1210003,
    message: 'credential cannot be null or undefined.'
  };
  static readonly USER_UNLINK_FAILED: AuthErrorCode = {
    code: 1210004,
    message: 'provider cannot be null or undefined.'
  };
  static readonly ALREADY_SIGN_IN_USER: AuthErrorCode = {
    code: 1210005,
    message: 'already sign in a user ,please sign out at first.'
  };
  static readonly FAIL_TO_GET_ACCESS_TOKEN: AuthErrorCode = {
    code: 1210006,
    message: 'get user access token fail.'
  };
  static readonly FAIL_TO_UPDATE_PROFILE: AuthErrorCode = {
    code: 1210007,
    message: 'update user profile fail'
  };
  static readonly FAIL_TO_UPDATE_EMAIL: AuthErrorCode = {
    code: 1210008,
    message: 'email or verify code can not be null or undefined.'
  };

  static readonly CREDENTIAL_INVALID: AuthErrorCode = {
    code: 1210009,
    message: 'credential is null.'
  };
}

export interface AuthErrorCode {
  code: number;
  message: string;
}
