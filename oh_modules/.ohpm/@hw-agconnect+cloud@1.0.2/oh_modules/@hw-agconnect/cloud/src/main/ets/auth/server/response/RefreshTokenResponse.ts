import { BaseResponse } from '@hw-agconnect/hmcore';
import { TokenInfo } from '../../entity/TokenInfo';

export class RefreshTokenResponse extends BaseResponse {
  accessToken: TokenInfo = new TokenInfo();
  productId: string = '';
  uid: string = '';

  constructResponse(response: any): boolean {
    this.accessToken.setToken(response.accessToken.token);
    this.accessToken.setValidPeriod(response.accessToken.validPeriod);
    this.productId = response.productId;
    this.uid = response.uid;
    return true;
  }
}
