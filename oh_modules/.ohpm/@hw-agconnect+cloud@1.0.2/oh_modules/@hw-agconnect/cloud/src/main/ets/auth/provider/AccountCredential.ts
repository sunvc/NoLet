import { AGConnectAuthCredential } from '../AuthInnerInterface';
import { ReauthenticateRequest } from '../server/request/ReauthenticateRequest';
import { SignInRequest } from '../server/request/SignInRequest';
import { UserLinkRequest } from '../server/request/UserLinkRequest';

export abstract class AccountCredential implements AGConnectAuthCredential {
  password: string | undefined;
  verifyCode: string | undefined;

  getProvider(): number {
    return -1;
  }

  /**
   * 此接口由内部使用
   *
   * @param request 登录请求
   */
  public abstract prepareUserAuthRequest(request: SignInRequest): void;

  /**
   * 此接口由内部使用
   *
   * @param request 重认证请求
   */
  public abstract prepareUserReauthRequest(request: ReauthenticateRequest): void;

  /**
   * 此接口由内部使用
   *
   * @param request 连接请求
   */
  public abstract prepareUserLinkRequest(request: UserLinkRequest): void;
}
