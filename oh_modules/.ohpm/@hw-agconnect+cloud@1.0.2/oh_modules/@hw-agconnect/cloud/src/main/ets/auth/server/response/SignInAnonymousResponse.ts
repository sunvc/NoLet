import { BaseResponse } from '@hw-agconnect/hmcore';
import { TokenInfo } from '../../entity/TokenInfo';
import { UserInfo } from '../../entity/UserInfo';

export class SignInAnonymousResponse extends BaseResponse {
  private accessToken: TokenInfo = new TokenInfo();
  private refreshToken: TokenInfo = new TokenInfo();
  private userInfo: UserInfo = new UserInfo();

  constructResponse(response: any): boolean {
    this.accessToken.setToken(response.accessToken?.token);
    this.accessToken.setValidPeriod(response.accessToken?.validPeriod);
    this.refreshToken.setToken(response.refreshToken?.token);
    this.refreshToken.setValidPeriod(response.refreshToken?.validPeriod);
    this.userInfo.setUid(response.uid);

    return true;
  }

  public getAccessToken(): TokenInfo {
    return this.accessToken;
  }

  public setAccessToken(accessToken: TokenInfo): void {
    this.accessToken = accessToken;
  }

  public getRefreshToken(): TokenInfo {
    return this.refreshToken;
  }

  public setRefreshToken(refreshToken: TokenInfo): void {
    this.refreshToken = refreshToken;
  }

  public getUserInfo(): UserInfo {
    return this.userInfo;
  }
}
