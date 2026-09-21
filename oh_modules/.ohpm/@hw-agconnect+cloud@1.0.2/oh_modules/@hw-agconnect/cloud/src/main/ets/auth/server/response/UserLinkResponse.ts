import { BaseResponse } from '@hw-agconnect/hmcore';

export class UserLinkResponse extends BaseResponse {
  private providerUserInfo: any | undefined = undefined;

  constructor() {
    super();
  }

  public getProviderUserInfo(): any | undefined {
    return this.providerUserInfo;
  }

  public setProviderUserInfo(providerUserInfo: any): void {
    this.providerUserInfo = providerUserInfo;
  }

  constructResponse(response: any): boolean {
    if (response.providerUserInfo) {
      this.setProviderUserInfo(response.providerUserInfo);
    }
    return true;
  }
}
