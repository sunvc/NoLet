import { Chain, Interceptor } from './Interceptor';
import { Response } from './Response';
import { SystemUtil } from '../util/SystemUtil';
import { getCore } from '../../core/hmcore';
import { SdkInfo } from '../../server/BaseRequest';

export class ApiInterceptor implements Interceptor {
  sdkInfo: SdkInfo;

  constructor(sdkInfo: SdkInfo) {
    this.sdkInfo = sdkInfo;
  }

  async apiInfo(): Promise<any> {
    return {
      sdkVersion: this.sdkInfo?.sdkVersion,
      sdkServiceName: this.sdkInfo?.sdkServiceName,
      sdkPlatform: 'OpenHarmony',
      sdkType: 'TS',
      sdkPlatformVersion: SystemUtil.getOsVersion(),
      packageName: SystemUtil.getPackageName(getCore().context),
      appVersion: await SystemUtil.getAppVersion(getCore().context),
      appId: getCore().appConfig?.app_id,
      client_id: getCore().appConfig?.client_id,
      productId: getCore().appConfig?.product_id,
      'Content-Type': 'application/json;charset=UTF-8'
    };
  }

  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    let apiInfo = await this.apiInfo();
    if (!request.header) {
      request.header = {};
    }
    for (const key in apiInfo) {
      if (!request.header[key]) {
        request.header[key] = apiInfo[key];
      }
    }
    return chain.proceed(request);
  }
}
