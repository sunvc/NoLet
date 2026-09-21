import {
  AuthUser,
  SignInResult,
  TokenResult,
  AuthUserExtra,
  UserProfileInfo,
  EmailInfo,
  PhoneInfo,
  PasswordInfo,
  ProviderType,
  CredentialInfo,
  SignInParam,
  PhoneCredentialInfo,
  EmailCredentialInfo
} from '../Auth';

import { UserExtraRequest } from '../server/request/UserExtraRequest';
import { UserExtraResponse } from '../server/response/UserExtraResponse';
import { StoredManager } from '../storage/StoredManager';
import { PhoneUtil } from '../utils/PhoneUtil';
import { Constant } from '../utils/Constant';
import { UpdatePasswordResponse } from '../server/response/UpdatePasswordResponse';
import { UpdatePasswordRequest } from '../server/request/UpdatePasswordRequest';
import { UpdatePhoneRequest } from '../server/request/UpdatePhoneRequest';
import { UpdatePhoneResponse } from '../server/response/UpdatePhoneResponse';
import { UpdateEmailRequest } from '../server/request/UpdateEmailRequest';
import { UpdateEmailResponse } from '../server/response/UpdateEmailResponse';
import { AGCAuthErrorCode } from '../exception/AGCAuthErrorCode';
import { AGCAuthError } from '../exception/AGCAuthError';
import { SignInResultImpl } from '../entity/SignInResultImpl';
import { Logger } from '@hw-agconnect/hmcore';
import { UserLinkRequest } from '../server/request/UserLinkRequest';
import { AccountCredential } from '../provider/AccountCredential';
import { ReauthenticateResponse } from '../server/response/ReauthenticateResponse';
import { ReauthenticateRequest } from '../server/request/ReauthenticateRequest';
import { UpdateProfileRequest } from '../server/request/UpdateProfileRequest';
import { UpdateProfileResponse } from '../server/response/UpdateProfileResponse';
import { UserLinkResponse } from '../server/response/UserLinkResponse';
import { UserUnlinkRequest } from '../server/request/UserUnlinkRequest';
import { UserUnlinkResponse } from '../server/response/UserUnlinkResponse';
import { UserRawData } from './UserRawData';
import { PhoneAuthProvider } from '../provider/PhoneAuthProvider';
import { EmailAuthProvider } from '../provider/EmailAuthProvider';
import { AuthBackend } from '../server/AuthBackend';
import { TokenImpl } from '../entity/TokenImpl';
import { RefreshTokenResponse } from '../server/response/RefreshTokenResponse';
import { RefreshTokenRequest } from '../server/request/RefreshTokenRequest';
import { AGConnectAuthCredential, AGConnectAuthCredentialProvider } from '../AuthInnerInterface';
import { Interceptor } from '@hw-agconnect/hmcore';
import { AuthTokenInterceptor } from '../utils/AuthTokenInterceptor';
import List from '@ohos.util.List';

const TAG: string = 'AGConnectDefaultUser';

export class AuthDefaultUser implements AuthUser {
  anonymous: boolean = false;
  uid: string = '';
  displayName: string = '';
  photoUrl: string = '';
  email: string = '';
  phone: string = '';
  providerId: string = '';
  emailVerified: number = 0;
  passwordSetted: number = 0;
  providerService: ProviderInfoService = new ProviderInfoService();
  tokenService: SecureTokenService = new SecureTokenService();
  storeManager: StoredManager;
  authBackend: AuthBackend;

  public setStoreManager(storeManager: StoredManager) {
    this.storeManager = storeManager;
  }

  public setAuthBackend(authBackend: AuthBackend) {
    this.authBackend = authBackend;
  }

  static fromRawData(info: UserRawData) {
    let user = new AuthDefaultUser();
    user.anonymous = info.anonymous;
    user.uid = info.uid;
    user.displayName = info.displayName;
    user.photoUrl = info.photoUrl;
    user.email = info.email;
    user.phone = info.phone;
    user.providerId = info.providerId;
    user.emailVerified = info.emailVerified;
    user.passwordSetted = info.passwordSetted;
    user.providerService.providerInfo = info.providerInfo;
    user.tokenService.accessToken = info.accessToken;
    user.tokenService.accessTokenValidPeriod = info.accessTokenValidPeriod;
    user.tokenService.refreshToken = info.refreshToken;
    user.tokenService.startTime = info.startTime;
    return user;
  }

  toRawData(): UserRawData {
    let info: UserRawData = {
      anonymous: this.anonymous,
      uid: this.uid,
      displayName: this.displayName,
      photoUrl: this.photoUrl,
      email: this.email,
      phone: this.phone,
      providerId: this.providerId,
      emailVerified: this.emailVerified,
      passwordSetted: this.passwordSetted,
      providerInfo: this.providerService.providerInfo,
      accessToken: this.tokenService.accessToken,
      accessTokenValidPeriod: this.tokenService.accessTokenValidPeriod,
      refreshToken: this.tokenService.refreshToken,
      startTime: this.tokenService.startTime
    };
    return info;
  }

  getUid(): string {
    return this.uid;
  }

  getEmail(): string {
    return this.email;
  }

  getPhone(): string {
    return this.phone;
  }

  getDisplayName(): string {
    return this.displayName;
  }

  getPhotoUrl(): string {
    return this.photoUrl;
  }

  getProviderId(): string {
    return this.providerId;
  }

  isAnonymous(): boolean {
    return this.anonymous;
  }

  getProviderInfo(): Map<string, string>[] {
    let res = new Array<Map<string, string>>();
    for (let i = 0; i < this.providerService.providerInfo?.length; i++) {
      let infoMap = new Map<string, string>();
      let allkey = Object.keys(this.providerService.providerInfo[i]);
      for (let j = 0; allkey && j < allkey.length; j++) {
        infoMap.set(allkey[j], this.providerService.providerInfo[i][allkey[j]]);
      }
      res.push(infoMap);
    }
    return res;
  }

  async getToken(forceRefresh: boolean): Promise<TokenResult> {
    if (!forceRefresh && this.tokenService.isValidAccessToken()) {
      return Promise.resolve(this.tokenService.getTokenResult());
    }
    await this.tokenService.refreshAllToken();
    await this.syncToStorage();
    return Promise.resolve(this.tokenService.getTokenResult());
  }

  async getUserExtra(): Promise<AuthUserExtra> {
    let userExtraRequest: UserExtraRequest = new UserExtraRequest();
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    let userExtraResponse = <UserExtraResponse>(
      await this.authBackend.get(userExtraRequest, new UserExtraResponse(), icList)
    );
    this.displayName = userExtraResponse.displayName;
    this.photoUrl = userExtraResponse.photoUrl;
    this.emailVerified = userExtraResponse.emailVerified;
    this.passwordSetted = userExtraResponse.passwordSetted;
    this.email = userExtraResponse.email;
    this.phone = userExtraResponse.phone;
    this.displayName = userExtraResponse.displayName;
    await this.syncToStorage();
    return Promise.resolve(userExtraResponse.userExtra);
  }

  getAccessToken(): string {
    return this.tokenService.getAccessToken();
  }

  getRefreshToken(): string {
    return this.tokenService.getRefreshToken();
  }

  getEmailVerified(): boolean {
    return this.emailVerified == 1;
  }

  getPasswordSetted(): boolean {
    return this.passwordSetted == 1;
  }

  async updateProfile(userProfile: UserProfileInfo): Promise<void> {
    if (!userProfile.displayName || !userProfile.photoUrl) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.FAIL_TO_UPDATE_PROFILE));
    }
    let profileRequest: UpdateProfileRequest = new UpdateProfileRequest();
    profileRequest.setDisplayName(userProfile.displayName);
    profileRequest.setPhotoUrl(userProfile.photoUrl);
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    await this.authBackend.put(profileRequest, new UpdateProfileResponse(), icList);
    this.displayName = userProfile.displayName;
    this.photoUrl = userProfile.photoUrl;
    await this.syncToStorage();
  }

  async userReauthenticate(param: SignInParam): Promise<SignInResult> {
    // make autoCreateUser default true
    let signInParam = { 'autoCreateUser': false, ...param };

    let credentialInfo = signInParam.credentialInfo;
    if (!credentialInfo) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.CREDENTIAL_INVALID));
    }

    let requestMaker = {
      'phone': (): ReauthenticateRequest => {
        let req = new ReauthenticateRequest();
        let phoneCredentialInfo = credentialInfo as PhoneCredentialInfo;
        let credential = PhoneAuthProvider.credentialWithPasswordAndVerifyCode(
          phoneCredentialInfo.countryCode,
          phoneCredentialInfo.phoneNumber,
          phoneCredentialInfo.password,
          phoneCredentialInfo.verifyCode
        );
        credential.prepareUserReauthRequest(req);
        return req;
      },
      'email': (): ReauthenticateRequest => {
        let req = new ReauthenticateRequest();
        let emailInfo = credentialInfo as EmailCredentialInfo;
        let credential = EmailAuthProvider.credentialWithPasswordAndVerifyCode(
          emailInfo.email,
          emailInfo.password,
          emailInfo.verifyCode
        );
        credential.prepareUserReauthRequest(req);
        return req;
      }
    };
    let reauthenticateRequest = requestMaker[signInParam.credentialInfo.kind]();
    reauthenticateRequest.setAutoCreateUser(signInParam.autoCreateUser);
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    let response = <ReauthenticateResponse>(
      await this.authBackend.post(reauthenticateRequest, new ReauthenticateResponse(), icList)
    );
    this.reConfigUserFrom(response);
    await this.syncToStorage();
    return Promise.resolve(new SignInResultImpl(this));
  }

  reConfigUserFrom(response: ReauthenticateResponse) {
    this.anonymous = false;
    this.uid = response.getUserInfo().getUid();
    this.displayName = response.getUserInfo().getDisplayName();
    this.photoUrl = response.getUserInfo().getPhotoUrl();
    this.email = response.getUserInfo().getEmail();
    this.emailVerified = response.getUserInfo().getEmailVerified();
    this.passwordSetted = response.getUserInfo().getPasswordSetted();
    this.phone = response.getUserInfo().getPhone();
    this.providerId = response.getUserInfo().getProvider().toString();
    this.tokenService.accessToken = response.getAccessToken().getToken();
    this.tokenService.accessTokenValidPeriod = response.getAccessToken().getValidPeriod();
    this.tokenService.refreshToken = response.getRefreshToken().getToken();
    this.tokenService.startTime = new Date().getTime();
    this.providerService.providerInfo = response.getProviders();
  }

  async link(credentialInfo: CredentialInfo): Promise<SignInResult> {
    let credentialMaker = {
      'phone': (): AGConnectAuthCredential => {
        let phoneCredentialInfo = credentialInfo as PhoneCredentialInfo;
        return PhoneAuthProvider.credentialWithPasswordAndVerifyCode(
          phoneCredentialInfo.countryCode,
          phoneCredentialInfo.phoneNumber,
          phoneCredentialInfo.password,
          phoneCredentialInfo.verifyCode
        );
      },
      'email': (): AGConnectAuthCredential => {
        let emailCredentialInfo = credentialInfo as EmailCredentialInfo;
        return EmailAuthProvider.credentialWithPasswordAndVerifyCode(
          emailCredentialInfo.email,
          emailCredentialInfo.password,
          emailCredentialInfo.verifyCode
        );
      }
    };
    let credential = credentialMaker[credentialInfo.kind]();
    if (!credential) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.USER_LINK_FAILED));
    }
    let userLinkRequest: UserLinkRequest = new UserLinkRequest();
    let provider = credential.getProvider();
    if (
      provider == AGConnectAuthCredentialProvider.Email_Provider ||
      provider == AGConnectAuthCredentialProvider.Phone_Provider
    ) {
      Logger.info(TAG, 'credential is AccountCredential');
      (credential as AccountCredential).prepareUserLinkRequest(userLinkRequest);
    }

    let self = this;
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    let userLinkResponse = <UserLinkResponse>(
      await this.authBackend.post(userLinkRequest, new UserLinkResponse(), icList)
    );
    let userInfo = userLinkResponse.getProviderUserInfo();
    if (userInfo) {
      let map: { [key: string]: string } = {};
      self.userInfoToMap(userInfo, map);
      if (self.anonymous) {
        self.updateAnonymousUserInfo(map);
      }
      self.providerService.updateProvider(map);
      if (map[Constant.Key.MapProviderKey]) {
        let providerStr: string = map[Constant.Key.MapProviderKey]!;
        if (AGConnectAuthCredentialProvider.Email_Provider.toString() == providerStr) {
          let linkEmail = map[Constant.Key.MapEmailKey];
          if (linkEmail) {
            self.email = linkEmail;
            self.emailVerified = 1;
          }
        } else if (AGConnectAuthCredentialProvider.Phone_Provider.toString() == providerStr) {
          let linkPhone = map[Constant.Key.MapPhoneKey];
          if (linkPhone) {
            self.phone = linkPhone;
          }
        }
        if (
          provider == AGConnectAuthCredentialProvider.Email_Provider ||
          provider == AGConnectAuthCredentialProvider.Phone_Provider
        ) {
          let cre = credential as AccountCredential;
          if (cre.password != undefined && cre.password != null && cre.password != '') {
            self.passwordSetted = 1;
          }
        }
      }
    }
    await this.syncToStorage();
    return Promise.resolve(new SignInResultImpl(this));
  }

  async unlink(type: ProviderType): Promise<SignInResult> {
    let credentialProvider = this.convertProvider(type);
    if (!credentialProvider) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.USER_UNLINK_FAILED));
    }
    let userUnLinkRequest = new UserUnlinkRequest();
    userUnLinkRequest.setProvider(credentialProvider);
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    await this.authBackend.post(userUnLinkRequest, new UserUnlinkResponse(), icList);
    this.providerService.deleteProvider(credentialProvider.toString());
    if (credentialProvider == AGConnectAuthCredentialProvider.Email_Provider) {
      this.email = '';
      this.emailVerified = 0;
    }
    if (credentialProvider == AGConnectAuthCredentialProvider.Phone_Provider) {
      this.phone = '';
    }

    if (
      this.providerService.findProviderIndex(
        AGConnectAuthCredentialProvider.Email_Provider.toString()
      ) == undefined &&
      this.providerService.findProviderIndex(
        AGConnectAuthCredentialProvider.Phone_Provider.toString()
      ) == undefined
    ) {
      this.passwordSetted = 0;
    }
    await this.syncToStorage();
    return Promise.resolve(new SignInResultImpl(this));
  }

  async updateEmail(emailInfo: EmailInfo): Promise<void> {
    let { email, verifyCode, lang } = emailInfo;
    if (!email || !verifyCode) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.FAIL_TO_UPDATE_EMAIL));
    }
    let updateEmailRequest: UpdateEmailRequest = new UpdateEmailRequest();
    updateEmailRequest.setNewEmail(email);
    updateEmailRequest.setNewVerifyCode(verifyCode);
    updateEmailRequest.setLang(lang);
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    await this.authBackend.put(updateEmailRequest, new UpdateEmailResponse(), icList);
    this.email = email;
    this.providerService.updateEmail(email);
    await this.syncToStorage();
    return Promise.resolve();
  }

  async updatePhone(phoneInfo: PhoneInfo): Promise<void> {
    let { phoneNumber, countryCode, verifyCode, lang } = phoneInfo;
    let updatePhoneReq: UpdatePhoneRequest = new UpdatePhoneRequest();
    updatePhoneReq.countryCode = countryCode;
    updatePhoneReq.newPhone = phoneNumber;
    updatePhoneReq.newVerifyCode = verifyCode;
    updatePhoneReq.lang = lang;
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    await this.authBackend.put(updatePhoneReq, new UpdatePhoneResponse(), icList);
    let combinatePhone = PhoneUtil.combinatePhone(countryCode, phoneNumber);
    this.phone = combinatePhone;
    this.providerService.updatePhone(combinatePhone);
    await this.syncToStorage();
    return Promise.resolve();
  }

  async updatePassword(passwordInfo: PasswordInfo): Promise<void> {
    let { password, verifyCode, providerType } = passwordInfo;
    let provider = this.convertProvider(providerType);
    let updatePasswordReq: UpdatePasswordRequest = new UpdatePasswordRequest();
    updatePasswordReq.setProvider(provider);
    updatePasswordReq.setNewPassword(password);
    updatePasswordReq.setNewverifyCode(verifyCode);
    let icList = new List<Interceptor>();
    icList.add(this.createTokenInterceptor());
    await this.authBackend.put(updatePasswordReq, new UpdatePasswordResponse(), icList);
    // 更新密码成功后,如果passwordSetted为0,则将passwordSetted设置为1
    if (this.passwordSetted == 0) {
      this.passwordSetted = 1;
    }
    return Promise.resolve();
  }

  private updateAnonymousUserInfo(info: { [key: string]: string }): void {
    this.anonymous = false;
    this.displayName = info[Constant.Key.MapDisplayNameKey]
      ? info[Constant.Key.MapDisplayNameKey]!
      : '';
    this.photoUrl = info[Constant.Key.MapPhotoUrlKey] ? info[Constant.Key.MapPhotoUrlKey]! : '';
    this.email = info[Constant.Key.MapEmailKey] ? info[Constant.Key.MapEmailKey]! : '';
    this.phone = info[Constant.Key.MapPhoneKey] ? info[Constant.Key.MapPhoneKey]! : '';
    this.providerId = info[Constant.Key.MapProviderKey] ? info[Constant.Key.MapProviderKey]! : '';
  }

  private userInfoToMap(userInfo: any, map: { [key: string]: string }) {
    if (userInfo.uid) {
      map[Constant.Key.MapUidKey] = userInfo.uid.toString();
    }
    if (userInfo.displayName) {
      map[Constant.Key.MapDisplayNameKey] = userInfo.displayName.toString();
    }
    if (userInfo.photoUrl) {
      map[Constant.Key.MapPhotoUrlKey] = userInfo.photoUrl.toString();
    }
    if (userInfo.email) {
      map[Constant.Key.MapEmailKey] = userInfo.email.toString();
    }
    if (userInfo.phone) {
      map[Constant.Key.MapPhoneKey] = userInfo.phone.toString();
    }
    if (userInfo.provider) {
      map[Constant.Key.MapProviderKey] = userInfo.provider.toString();
    }
    if (userInfo.openId) {
      map[Constant.Key.MapOpenIdKey] = userInfo.openId.toString();
    }
  }

  public async dispose(): Promise<void> {
    await this.storeManager.saveToStorage(null);
  }

  public async syncToStorage(): Promise<void> {
    let info = this.toRawData();
    await this.storeManager.saveToStorage(info);
  }

  createTokenInterceptor(): Interceptor {
    return new AuthTokenInterceptor(this);
  }

  private convertProvider(providerType: ProviderType) {
    let providerMap = {
      'phone': AGConnectAuthCredentialProvider.Phone_Provider,
      'email': AGConnectAuthCredentialProvider.Email_Provider
    };
    return providerMap[providerType];
  }
}

class SecureTokenService {
  private readonly TIME_EARLY: number = 5 * 60 * 1000;

  accessToken: string = '';

  accessTokenValidPeriod: number = -1;

  refreshToken: string = '';

  validTime: number = -1;

  startTime: number = -1;

  getAccessToken(): string {
    return this.accessToken;
  }

  getRefreshToken(): string {
    return this.refreshToken;
  }

  isValidAccessToken(): boolean {
    if (!this.accessToken) {
      return false;
    }
    let alarmTime = this.startTime + this.accessTokenValidPeriod * 1000 - this.TIME_EARLY;
    return new Date().getTime() < alarmTime;
  }

  getTokenResult(): TokenResult {
    return new TokenImpl(this.accessTokenValidPeriod, this.accessToken);
  }

  async refreshAllToken(): Promise<void> {
    if (!this.accessToken || !this.refreshToken) {
      return Promise.reject(new AGCAuthError(AGCAuthErrorCode.NULL_TOKEN));
    }
    let refreshTokenRequest = new RefreshTokenRequest(this.refreshToken);
    let refreshTokenResponse = <RefreshTokenResponse>(
      await new AuthBackend().post(refreshTokenRequest, new RefreshTokenResponse())
    );
    this.accessToken = refreshTokenResponse.accessToken.getToken();
    this.accessTokenValidPeriod = refreshTokenResponse.accessToken.getValidPeriod();
    this.startTime = new Date().getTime();
  }
}
/*
 * ProviderInfoService类实现Provider信息的设置、获取、更新、删除操作
 * 内部数据结构为Map数组
 * Map映射关系为 ProviderInfo: string -> Provider_details: string
 */
class ProviderInfoService {
  providerInfo: Array<{ [key: string]: string }> = new Array<{ [key: string]: string }>();

  updateProvider(info: { [key: string]: string }): void {
    if (info && this.providerInfo) {
      let providerId = info[Constant.Key.MapProviderKey];
      if (providerId) {
        this.deleteProvider(providerId);
      }
      this.providerInfo.push(info);
    }
  }

  updateProviderInfo(provider: number, key: string, value: string): void {
    let index: number | undefined = this.findProviderIndex(provider.toString());
    if (index != undefined) {
      this.providerInfo[index][key] = value;
    }
  }

  updateEmail(newEmail: string): void {
    this.updateProviderInfo(
      AGConnectAuthCredentialProvider.Email_Provider,
      Constant.Key.MapEmailKey,
      newEmail
    );
  }

  updatePhone(newPhone: string): void {
    this.updateProviderInfo(
      AGConnectAuthCredentialProvider.Phone_Provider,
      Constant.Key.MapPhoneKey,
      newPhone
    );
  }

  deleteProvider(provider: string): void {
    let index = this.findProviderIndex(provider);
    if (!this.providerInfo || index == undefined) {
      return;
    }
    this.providerInfo.splice(index, 1);
  }

  findProviderIndex(provider: string): number | undefined {
    let index: number | undefined = undefined;
    if (provider && this.providerInfo) {
      for (let i = 0; i < this.providerInfo.length; i++) {
        let info = this.providerInfo[i];
        if (info && provider == info[Constant.Key.MapProviderKey]) {
          index = i;
          break;
        }
      }
    }
    return index;
  }
}
