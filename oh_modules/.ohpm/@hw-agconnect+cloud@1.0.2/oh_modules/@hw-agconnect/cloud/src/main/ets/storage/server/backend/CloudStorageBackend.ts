import { Backend } from '@hw-agconnect/hmcore';
import { CloudStorageRequest } from '../request/CloudStorageRequest';
import { Method } from '@hw-agconnect/hmcore';
import { AddressCount, CloudStorageConfig } from '../../utils/CloudStorageConfig';
import { sleep } from '../../utils/sleep';
import hmcloud from '../../../hmcloud';
import AccessTokenInterceptor from '../../../utils/AccessTokenInterceptor';
import { Interceptor } from '@hw-agconnect/hmcore';
import { AGCError } from '@hw-agconnect/hmcore';
import List from '@ohos.util.List';

export class CloudStorageBackend {
  static readonly TAG = 'CloudStorageBackend';
  private accessTokenInterceptor: Interceptor;

  constructor() {
    this.accessTokenInterceptor = new AccessTokenInterceptor({
      auth: () => {
        return hmcloud.auth();
      }
    });
  }

  public async makeRequest(
    requestInfo: CloudStorageRequest<any>,
    retryTimes: number,
    lastUrl?: string
  ): Promise<any> {
    let config = CloudStorageConfig.getInstance();
    const urlInfo = config.getHostByRegion(requestInfo.area);
    let icList = new List<Interceptor>();
    icList.add(this.accessTokenInterceptor);
    let options = {
      clientToken: true
    };
    try {
      let resResult = await Backend.sendRequest(
        requestInfo.method as Method,
        requestInfo,
        options,
        icList
      );
      return this.doThen(requestInfo, resResult, urlInfo);
    } catch (e) {
      return this.doCatch(
        requestInfo,
        e,
        retryTimes,
        urlInfo.url,
        lastUrl === urlInfo.url ? urlInfo : undefined
      );
    }
  }

  private doThen(
    requestInfo: CloudStorageRequest<any>,
    resResult: any,
    addressCount: AddressCount
  ): Promise<any> {
    let config = CloudStorageConfig.getInstance();
    config.clearHostCount(requestInfo.area, addressCount.index);
    const result = requestInfo.handle(resResult);
    return Promise.resolve(result);
  }

  private async doCatch(
    requestInfo: CloudStorageRequest<any>,
    error: AGCError,
    retryTimes: number,
    url: string,
    addressCount?: AddressCount
  ): Promise<any> {
    let unKnownHost = (code: number) => code in [3, 6, 7, 28, 60];
    if (addressCount && unKnownHost(error.code)) {
      let config = CloudStorageConfig.getInstance();
      config.setHostCount(requestInfo.area, addressCount.index);
    }
    if (retryTimes >= requestInfo.maxRetryTimes) {
      return Promise.reject(error);
    } else {
      if (!requestInfo.ignoreRetryWaiting) {
        let waitSeconds: number = retryTimes < 6 ? Math.pow(2, retryTimes + 1) : 64;
        await sleep(waitSeconds * 1000);
      }
      return this.makeRequest(requestInfo, retryTimes + 1, url); // 重试
    }
  }
}
