export interface TokenResult {
  /**
   * 获取用户的Access Token
   *
   * @return AT
   */
  getString(): string;

  /**
   * 获取Token的有效期
   *
   * @return 有效期 单位：秒
   */
  getExpirePeriod(): number;
}

export declare interface SignInResult {
  /**
   * 返回当前登录的用户信息
   * @return 当前登录的用户信息
   */
  getUser(): AuthUser;
}

export interface PhoneVerifyCode {
  kind: 'phone';
  phoneNumber: string;
  countryCode: string;
}

export interface EmailVerifyCode {
  kind: 'email';
  email: string;
}

export interface VerifyCodeParam {
  verifyCodeType: PhoneVerifyCode | EmailVerifyCode;
  action: VerifyCodeAction;
  lang: string;
  sendInterval?: number;
}

export interface PhoneCredentialInfo {
  kind: 'phone';
  countryCode: string;
  phoneNumber: string;
  password?: string;
  verifyCode?: string;
}

export interface EmailCredentialInfo {
  kind: 'email';
  email: string;
  password?: string;
  verifyCode?: string;
}

export type CredentialInfo = PhoneCredentialInfo | EmailCredentialInfo;

export interface SignInParam {
  credentialInfo: CredentialInfo;
  autoCreateUser?: boolean;
}

export interface PhoneInfo {
  phoneNumber: string;
  countryCode: string;
  verifyCode: string;
  lang: string;
}

export interface EmailInfo {
  email: string;
  verifyCode: string;
  lang: string;
}

export type ProviderType = 'email' | 'phone';

export interface PasswordInfo {
  password: string;
  verifyCode: string;
  providerType: ProviderType;
}

export type UserProfileInfo = {
  displayName: string;
  photoUrl: string;
};

export declare interface Auth {
  /**
   * 申请验证码
   * @param 验证码配置参数
   */
  requestVerifyCode(verifyCodeParam: VerifyCodeParam): Promise<VerifyCodeResult>;

  /**
   * 创建账户
   * @return 登录结果异步任务, 在任务成功后通过<code>getUser</code>获取登录的用户信息。
   */
  createUser(credentialInfo: CredentialInfo): Promise<SignInResult>;

  /**
   * 重置密码
   * @param countryCode 国家码
   * @param phoneNumber 手机号
   * @param email 邮箱
   * @param newPassword 新密码
   * @param verifyCode 邮箱获取的验证码
   * @return 重置结果异步任务, 在任务成功后通过signIn重新登录。
   */

  resetPassword(credentialInfo: CredentialInfo): Promise<void>;
  /**
   * 登录接口，通过第三方认证来登录AGConnect平台
   *
   * @param credential 第三方OAuth2认证的凭证，需要通过对应的AuthProvider去创建。
   * @return 登录结果异步任务, 在任务成功后通过<code>getUser</code>获取登录的用户信息。
   */
  signIn(signInParam: SignInParam): Promise<SignInResult>;
  /**
   * 匿名登陆
   *
   * @return 登录结果异步任务, 在任务成功后通过<code>getUser</code>获取登录的用户信息。
   */
  signInAnonymously(): Promise<SignInResult>;
  /**
   * 在AGConnect服务器侧删除当前用户信息同时清除缓存信息
   */
  deleteUser(): Promise<void>;

  /**
   * 登出接口
   * 退出登录状态，删除缓存数据
   */
  signOut(): Promise<void>;

  /**
   * 获取当前登录的用户信息，如果未登录则返回null
   *
   * @return 当前用户信息
   */
  getCurrentUser(): Promise<AuthUser | null>;
}

export interface AuthUser {
  /**
   * 用户id，此id由AGConnect生成
   *
   * @return 用户id
   */
  getUid(): string;

  /**
   * 用户Email
   *
   * @return 用户Email
   */
  getEmail(): string;

  /**
   * 用户Phone
   *
   * @return 用户Phone
   */
  getPhone(): string;

  /**
   * 用户名称
   *
   * @return 用户名称
   */
  getDisplayName(): string;

  /**
   * 用户头像
   *
   * @return 头像地址
   */
  getPhotoUrl(): string;

  /**
   * 当前用户的提供者，第三方认证平台的名称
   *
   * @return 用户的提供者
   */
  getProviderId(): string;

  /**
   * 全部第三方平台的用户信息
   *
   * @return 当前登录的各个第三方认证平台用户信息的列表
   */
  getProviderInfo(): Array<Map<string, string>>;

  /**
   * 获取AGC用户的Access Token
   *
   * @param forceRefresh 是否强制刷新
   * @return 用户的Access Token 信息
   */
  getToken(forceRefresh: boolean): Promise<TokenResult>;

  /**
   * 获取当前用户的Extra信息
   *
   * @return 获取结果异步任务
   */
  getUserExtra(): Promise<AuthUserExtra>;

  /**
   * 是否是匿名登录用户
   *
   * @return 是否是匿名用户
   */
  isAnonymous(): boolean;

  /**
   * 邮箱验证标记
   *
   * @return 邮箱验证标记
   */
  getEmailVerified(): boolean;

  /**
   * 密码设置标记
   *
   * @return 密码设置标记
   */
  getPasswordSetted(): boolean;
  /**
   * 当前用户关联新的登录方式
   *
   * @param credential 新的第三方登录凭证
   * @return 登录结果异步任务, 在任务成功后通过<code>getUser</code>获取登录的用户信息。
   */
  link(credentialInfo: CredentialInfo): Promise<SignInResult>;

  /**
   * 当前用户解除关联的登录方式
   *
   * @param provider 要解除的登录方式，对应的值参考AGConnectAuthCredential
   * @return 登录结果异步任务, 在任务成功后通过<code>getUser</code>获取登录的用户信息。
   */
  unlink(type: ProviderType): Promise<SignInResult>;

  /**
   * 更新当前用户邮箱
   *
   * @param newEmail 新邮箱地址
   * @param newVerifyCode 验证码
   * @param lang 语言，格式为zh_CN，参考设计文档标准
   * @return 更新结果异步任务
   */
  updateEmail(emailInfo: EmailInfo): Promise<void>;

  /**
   * 更新当前用户手机
   *
   * @param countryCode 国家码
   * @param newPhone 新手机号
   * @param newVerifyCode 验证码
   * @param lang 语言，格式为zh_CN，参考设计文档标准
   * @return 更新结果异步任务
   */
  updatePhone(phoneInfo: PhoneInfo): Promise<void>;

  /**
   * 更新当前用户密码
   *
   * @param newPassword 新密码
   * @param verifyCode 验证码，用户登录超过5分钟必填
   * @param provider 手机或邮箱标识,手机为11,邮箱为12
   * @return 更新结果异步任务
   */
  updatePassword(passwordInfo: PasswordInfo): Promise<void>;
  /**
   * 更新当前用户的个人信息
   *
   * @param userProfile 个人信息
   * @return 更新结果异步任务
   */
  updateProfile(userProfile: UserProfileInfo): Promise<void>;
  /**
   * 用户登陆后重认证
   *
   * @param credential 第三方OAuth2认证的凭证，需要通过对应的AuthProvider去创建。
   * @return 登录结果异步任务, 在任务成功后通过<code>getUser</code>获取登录的用户信息。
   */
  userReauthenticate(signInParam: SignInParam): Promise<SignInResult>;
}

export interface AuthUserExtra {
  /**
   * 创建用户时间
   *
   * @return 创建时间
   */
  getCreateTime(): string;

  /**
   * 最近一次登录时间
   *
   * @return 登录时间
   */
  getLastSignInTime(): string;
}

export interface VerifyCodeResult {
  /**
   * 两次发送验证码的最小时间间隔
   *
   * @return 最小时间间隔，单位：秒
   */
  getShortestInterval(): string;

  /**
   * 验证码有效期
   *
   * @return 有效期，单位：秒
   */
  getValidityPeriod(): string;
}

export enum VerifyCodeAction {
  REGISTER_LOGIN = 1001,
  RESET_PASSWORD = 1002
}

export {AGCAuthError} from './exception/AGCAuthError'
