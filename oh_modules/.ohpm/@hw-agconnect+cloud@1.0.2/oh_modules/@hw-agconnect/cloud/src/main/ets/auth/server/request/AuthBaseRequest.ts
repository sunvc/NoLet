import { BaseRequest } from '@hw-agconnect/hmcore';
import { getAppConfig } from '@hw-agconnect/hmcore';
import { getGrsConfig, getRegion, GRS_TYPE } from '@hw-agconnect/hmcore';
import { SdkInfo, URL } from '@hw-agconnect/hmcore';
import { cloudSDKInfo } from '../../../utils/SDKInfo';


export class AuthBaseRequest implements BaseRequest {
  protected readonly URL_PATH_PREFIX: string = '/agc/apigw/oauth2/third/v1';
  protected URL_PATH_SURFFIX: string = '';
  region_: string;
  accessToken: string = '';

  constructor(region?: string) {
    this.region_ = region ? region : getRegion();
  }

  region(): string {
    return this.region_;
  }

  sdkInfo(): SdkInfo {
    return cloudSDKInfo;
  }

  url(): URL {
    return {
      main:
      'https://' +
      getGrsConfig(GRS_TYPE.AGC_GW, this.region_) +
      this.URL_PATH_PREFIX +
      this.URL_PATH_SURFFIX +
      this.queryParam(),
      back:
      'https://' +
      getGrsConfig(GRS_TYPE.AGC_GW_BACK, this.region_) +
      this.URL_PATH_PREFIX +
      this.URL_PATH_SURFFIX +
      this.queryParam()
    };
  }

  async header(): Promise<any> {
    return null;
  }

  async body(): Promise<any> {
    return {};
  }

  queryParam(): string {
    let query = '';
    let config = getAppConfig();
    if (config?.product_id) {
      query = '?productId=' + config?.product_id;
    }
    return query;
  }
}
