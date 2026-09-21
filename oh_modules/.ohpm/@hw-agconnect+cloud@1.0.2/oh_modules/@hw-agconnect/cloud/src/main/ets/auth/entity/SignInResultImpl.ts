import { AuthUser, SignInResult } from '../Auth';

export class SignInResultImpl implements SignInResult {
  private user: AuthUser;

  constructor(user: AuthUser) {
    this.user = user;
  }
  /**
   * 返回当前登录的用户信息
   * @return 当前登录的用户信息
   */
  getUser(): AuthUser {
    return this.user;
  }
}
