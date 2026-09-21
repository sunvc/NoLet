import { BaseResponse } from '@hw-agconnect/hmcore';
import { TokenInfo } from '../../entity/TokenInfo';
import { UserInfo } from '../../entity/UserInfo';
import { Constant } from '../../utils/Constant';

export class SignInResponse extends BaseResponse {
  private accessToken: TokenInfo = new TokenInfo();
  private refreshToken: TokenInfo = new TokenInfo();
  private userInfo: UserInfo = new UserInfo();
  private providers: Array<{ [key: string]: string }> = [];

  constructResponse(response: any): boolean {
    this.accessToken.setToken(response.accessToken?.token);
    this.accessToken.setValidPeriod(response.accessToken?.validPeriod);

    this.refreshToken.setToken(response.refreshToken?.token);
    this.refreshToken.setValidPeriod(response.refreshToken?.validPeriod);

    this.userInfo.setUid(response.userInfo?.uid);
    this.userInfo.setEmail(response.userInfo?.email);
    this.userInfo.setPhone(response.userInfo?.phone);
    this.userInfo.setProvider(response.userInfo?.provider);
    this.userInfo.setEmailVerified(response.userInfo?.emailVerified);
    this.userInfo.setPasswordSetted(response.userInfo?.passwordSetted);
    this.userInfo.setDisplayName(response.userInfo?.displayName);
    this.userInfo.setOpenId(response.userInfo?.openId);
    this.userInfo.setPhotoUrl(response.userInfo?.photoUrl);

    let providers: Array<{ [key: string]: string }> = new Array<{ [key: string]: string }>();
    for (let i = 0; i < response.providers?.length; i++) {
      let map: { [key: string]: string } = {};
      this.userInfoToMap(response.providers[i], map);
      providers.push(map);
    }
    this.providers = providers;
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

  public getProviders(): Array<{ [key: string]: string }> {
    return this.providers;
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
}
