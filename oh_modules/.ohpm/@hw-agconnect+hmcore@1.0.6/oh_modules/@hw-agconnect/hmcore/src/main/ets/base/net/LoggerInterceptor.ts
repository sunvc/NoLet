import { Chain, Interceptor } from './Interceptor';
import { Response } from './Response';
import { Logger } from '../log/Logger';
import { SdkInfo } from '../../server/BaseRequest';

const TAG = 'HTTP';

export class LoggerInterceptor implements Interceptor {
  region: string;
  sdkInfo: SdkInfo;

  constructor(region: string, sdkInfo: SdkInfo) {
    this.region = region;
    this.sdkInfo = sdkInfo;
  }

  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    let msg = `${request.method}, region:${this.region},interface:${maskUrl(request.url)} serviceInfo:${this.sdkInfo.sdkServiceName}/${this.sdkInfo.sdkVersion}`;
    Logger.info(TAG, `--->${msg}`);
    let time = new Date().getTime();
    let response = await chain.proceed(request);
    Logger.info(
      TAG,
      `<---${msg} responseCode:${response.responseCode}, responseMsg:${
      response.message
      }, constTime:${new Date().getTime() - time}`
    );
    return response;
  }
}

function maskUrl(url: string): string {
  if (url) {
    let strArray: string[] = url.split('.');
    if (strArray && strArray.length > 0) {
      let re =/\//g;
      let result = strArray[strArray.length -1].replace(re, '');
      return result;
    }
  }
  return '';
}
