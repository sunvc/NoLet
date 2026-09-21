import { getGrsConfig, getRegion, GRS_TYPE } from '../core';
import { getCore } from '../core/hmcore';
import { BaseRequest, SdkInfo, URL } from '../server/BaseRequest';

export class ClientTokenRequest implements BaseRequest {
  interfaceId = '/agc/apigw/oauth2/v1/token';
  region_: string;

  constructor(region?: string) {
    this.region_ = region ? region : getRegion();
  }

  sdkInfo(): SdkInfo {
    return {
      sdkServiceName: 'agconnect-credential',
      sdkVersion: ''
    };
  }

  region(): string {
    return this.region_;
  }

  url(): URL {
    return {
      main: 'https://' + getGrsConfig(GRS_TYPE.AGC_GW, this.region_) + this.interfaceId,
      back: 'https://' + getGrsConfig(GRS_TYPE.AGC_GW_BACK, this.region_) + this.interfaceId
    };
  }

  header(): Promise<any> {
    return null;
  }

  async body(): Promise<any> {
    return {
      grant_type: 'client_credentials',
      client_id: getCore().appConfig?.client_id,
      client_secret: await getCore().getClientSecret(),
      useJwt: 1
    };
  }
}
