import {
  AuthUser,
  Auth,
  CredentialInfo,
  EmailCredentialInfo,
  EmailVerifyCode,
  PhoneCredentialInfo,
  PhoneVerifyCode,
  SignInParam,
  SignInResult,
  VerifyCodeParam,
  VerifyCodeResult
} from './Auth';
import { SignInResultImpl } from './entity/SignInResultImpl';
import { VerifyCodeResultImpl } from './entity/VerifyCodeResultIpml';
import { AGCAuthError } from './exception/AGCAuthError';
import { AGCAuthErrorCode } from './exception/AGCAuthErrorCode';
import { AuthBackend } from './server/AuthBackend';
import { SignInAnonymousRequest } from './server/request/SignInAnonymousRequest';
import { VerifyCodeRequest } from './server/request/VerifyCodeRequest';
import { SignInResponse } from './server/response/SignInResponse';
import { VerifyCodeResponse } from './server/response/VerifyCodeResponse';
import { PhoneUtil } from './utils/PhoneUtil';
import { RegisterUserRequest } from './server/request/RegisterUserRequest';
import { ResetPasswordRequest } from './server/request/ResetPasswordRequest';
import { SignInAnonymousResponse } from './server/response/SignInAnonymousResponse';
import { ResetPasswordResponse } from './server/response/ResetPasswordResponse';
import { SignInRequest } from './server/request/SignInRequest';
import { PhoneAuthProvider } from './provider/PhoneAuthProvider';
import { EmailAuthProvider } from './provider/EmailAuthProvider';
import { DeleteUserRequest } from './server/request/DeleteUserRequest';
import { DeleteUserResponse } from './server/response/DeleteUserResponse';
import { SignOutRequest } from './server/request/SignOutRequest';
import { Logger } from '@hw-agconnect/hmcore';
import { UserManager, UserManagerBuilder } from './user/UserManager';
import { SignOutResponse } from './server/response/SignOutResponse';
import { UserRawData } from './user/UserRawData';
import { AGConnectAuthCredentialProvider } from './AuthInnerInterface';
import { StoredManager } from './storage/StoredManager';
import { Interceptor } from '@hw-agconnect/hmcore';
import List from '@ohos.util.List';

const TAG: string = 'AuthImpl';

export class AuthImpl implements Auth {
  private authBackend: AuthBackend;
  region: string;
  userManager: UserManager;

  constructor(region: string) {
    console.info('cons');
    this.authBackend = new AuthBackend();
    this.region = region;
    this.userManager = new UserManagerBuilder()
      .setAuthBackend(this.authBackend)
      .setStoredManager(new StoredManager(this.region))
      .build();
  }

  async requestVerifyCode(verifyCodeParam: VerifyCodeParam): Promise<VerifyCodeResult> {
    let requestMaker = {
      'phone': (): VerifyCodeRequest => {
        let phoneVerifyCode = verifyCodeParam.verifyCodeType as PhoneVerifyCode;
        let req = new VerifyCodeRequest();
        req.setPhone(
          PhoneUtil.combinatePhone(phoneVerifyCode.countryCode, phoneVerifyCode.phoneNumber)
        );
        return req;
      },
      'email': (): VerifyCodeRequest => {
        let emailVerifyCode = verifyCodeParam.verifyCodeType as EmailVerifyCode;
        let req = new VerifyCodeRequest();
        req.setEmail(emailVerifyCode.email);
        return req;
      }
    };
    let req = requestMaker[verifyCodeParam.verifyCodeType.kind]();
    req.setAction(verifyCodeParam.action);
    req.setLang(verifyCodeParam.lang);
    req.setSendInterval(verifyCodeParam.sendInterval ? verifyCodeParam.sendInterval : 0);
    let verifyCodeResponse = <VerifyCodeResponse>(
      await this.authBackend.post(req, new VerifyCodeResponse())
    );
    return new VerifyCodeResultImpl(
      verifyCodeResponse.shortestInterval,
      verifyCodeResponse.validityPeriod
    );
  }

  async createUser(credentialInfo: CredentialInfo): Promise<SignInResult> {
    let requestMaker = {
      'phone': () => {
        let phoneInfo = credentialInfo as PhoneCredentialInfo;
        let req = new RegisterUserRequest();
        req.phone = PhoneUtil.combinatePhone(phoneInfo.countryCode, phoneInfo.phoneNumber);
        req.password = phoneInfo.password;
        req.verifyCode = phoneInfo.verifyCode;
        req.provider = AGConnectAuthCredentialProvider.Phone_Provider;
        return req;
      },
      'email': () => {
        let emailInfo = credentialInfo as EmailCredentialInfo;
        let req = new RegisterUserRequest();
        req.email = emailInfo.email;
        req.password = emailInfo.password;
        req.verifyCode = emailInfo.verifyCode;
        req.provider = AGConnectAuthCredentialProvider.Email_Provider;
        return req;
      }
    };
    let request = requestMaker[credentialInfo.kind]();
    let signInResponse = <SignInResponse>await this.authBackend.post(request, new SignInResponse());
    let user = await this.userManager.makeUserInstance(this.convertToUserInfo(signInResponse));
    return new SignInResultImpl(user);
  }

  async resetPassword(credentialInfo: CredentialInfo): Promise<void> {
    let requestMaker = {
      'phone': (): ResetPasswordRequest => {
        let req = new ResetPasswordRequest();
        let phoneInfo = credentialInfo as PhoneCredentialInfo;
        req.account = PhoneUtil.combinatePhone(phoneInfo.countryCode, phoneInfo.phoneNumber);
        req.newPassword = phoneInfo.password;
        req.verifyCode = phoneInfo.verifyCode;
        req.provider = AGConnectAuthCredentialProvider.Phone_Provider;
        return req;
      },
      'email': (): ResetPasswordRequest => {
        let req = new ResetPasswordRequest();
        let emailInfo = credentialInfo as EmailCredentialInfo;
        req.account = emailInfo.email;
        req.newPassword = emailInfo.password;
        req.verifyCode = emailInfo.verifyCode;
        req.provider = AGConnectAuthCredentialProvider.Email_Provider;
        return req;
      }
    };
    let request = requestMaker[credentialInfo.kind]();
    await this.authBackend.post(request, new ResetPasswordResponse());
    return Promise.resolve();
  }

  async signIn(param: SignInParam): Promise<SignInResult> {
    // make autoCreateUser default true
    let signInParam = { 'autoCreateUser': true, ...param };
    let user = await this.userManager.currentUserInstance();
    if (user) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.ALREADY_SIGN_IN_USER));
    }

    let credentialInfo = signInParam.credentialInfo;
    if (!credentialInfo) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.CREDENTIAL_INVALID));
    }

    let requestMaker = {
      'phone': (): SignInRequest => {
        let req = new SignInRequest();
        let phoneCredentialInfo = credentialInfo as PhoneCredentialInfo;
        let credential = PhoneAuthProvider.credentialWithPasswordAndVerifyCode(
          phoneCredentialInfo.countryCode,
          phoneCredentialInfo.phoneNumber,
          phoneCredentialInfo.password,
          phoneCredentialInfo.verifyCode
        );
        credential.prepareUserAuthRequest(req);
        req.setAutoCreateUser(signInParam.autoCreateUser);
        return req;
      },
      'email': (): SignInRequest => {
        let req = new SignInRequest();
        let emailInfo = credentialInfo as EmailCredentialInfo;
        let credential = EmailAuthProvider.credentialWithPasswordAndVerifyCode(
          emailInfo.email,
          emailInfo.password,
          emailInfo.verifyCode
        );
        credential.prepareUserAuthRequest(req);
        req.setAutoCreateUser(signInParam.autoCreateUser);
        return req;
      }
    };
    let request = requestMaker[signInParam.credentialInfo.kind]();
    let signInResponse = <SignInResponse>await this.authBackend.post(request, new SignInResponse());
    let newUser = await this.userManager.makeUserInstance(this.convertToUserInfo(signInResponse));
    return new SignInResultImpl(newUser);
  }

  async signInAnonymously(): Promise<SignInResult> {
    // check exists
    let user = await this.userManager.currentUserInstance();
    if (user) {
      if (user.isAnonymous()) {
        return new SignInResultImpl(user);
      }
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.ALREADY_SIGN_IN_USER));
    }
    // request
    let request = new SignInAnonymousRequest();
    let signInAnonymousResponse = <SignInAnonymousResponse>(
      await this.authBackend.post(request, new SignInAnonymousResponse())
    );

    // create user
    let newUser = await this.userManager.makeUserInstance(
      this.convertToUserInfo(signInAnonymousResponse, true)
    );
    return new SignInResultImpl(newUser);
  }

  async deleteUser(): Promise<void> {
    let user = await this.userManager.currentUserInstance();
    if (!user) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.NOT_SIGN_IN));
    }
    let deleteUserRequest = new DeleteUserRequest();
    let icList = new List<Interceptor>();
    icList.add(user.createTokenInterceptor());
    await this.authBackend.post(deleteUserRequest, new DeleteUserResponse(), icList);
    await this.userManager.disposeUserInstance();
  }

  async signOut(): Promise<void> {
    let user = await this.userManager.currentUserInstance();
    if (!user) {
      Logger.info(TAG, 'no user login in');
      return;
    }
    let signOutRequest = new SignOutRequest();
    signOutRequest.bodyAccessToken = user.getAccessToken();
    signOutRequest.refreshToken = user.getRefreshToken();
    // 不返回signout接口的返回值，不管云测返回是否成功失败，端侧强制清空数据
    try {
      await this.authBackend.post(signOutRequest, new SignOutResponse());
    } catch (e) {
      Logger.info(TAG, `logout error ${JSON.stringify(e)}`);
    }

    await this.userManager.disposeUserInstance();
  }

  async getCurrentUser(): Promise<AuthUser | null> {
    let user = await this.userManager.currentUserInstance();
    return user;
  }

  private convertToUserInfo(
    response: SignInResponse | SignInAnonymousResponse,
    isAnonymous: boolean = false
  ): UserRawData {
    if (isAnonymous) {
      let rsp: SignInAnonymousResponse = response as SignInAnonymousResponse;
      return {
        anonymous: true,
        uid: rsp.getUserInfo().getUid(),
        providerId: AGConnectAuthCredentialProvider.Anonymous.toString(),
        accessToken: rsp.getAccessToken().getToken(),
        accessTokenValidPeriod: rsp.getAccessToken().getValidPeriod(),
        refreshToken: rsp.getRefreshToken().getToken(),
        startTime: new Date().getTime()
      };
    }
    let rsp: SignInResponse = response as SignInResponse;
    return {
      anonymous: false,
      uid: rsp.getUserInfo().getUid(),
      displayName: rsp.getUserInfo().getDisplayName(),
      photoUrl: rsp.getUserInfo().getPhotoUrl(),
      email: rsp.getUserInfo().getEmail(),
      emailVerified: rsp.getUserInfo().getEmailVerified(),
      passwordSetted: rsp.getUserInfo().getPasswordSetted(),
      phone: rsp.getUserInfo().getPhone(),
      providerId: rsp.getUserInfo().getProvider().toString(),
      accessToken: rsp.getAccessToken().getToken(),
      accessTokenValidPeriod: rsp.getAccessToken().getValidPeriod(),
      refreshToken: rsp.getRefreshToken().getToken(),
      providerInfo: rsp.getProviders(),
      startTime: new Date().getTime()
    };
  }
}
