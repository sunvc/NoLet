import { BaseRequest } from '@hw-agconnect/hmcore';
import * as UrlUtils from '../../utils/url';
import { CloudStorageConfig } from '../../utils/CloudStorageConfig';
import { Location } from '../../implementation/location';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';
import { SdkInfo, URL, getAppConfig } from '@hw-agconnect/hmcore';
import { cloudSDKInfo } from '../../../utils/SDKInfo';

export interface UrlParams {
  [name: string]: string | number;
}

export class CloudStorageRequest<T> implements BaseRequest {
  urlParams: UrlParams = {};
  _body: string | ArrayBuffer | Uint8Array | null = null;
  successCodes: number[] = [200];
  progressCallback?: (progressEvent: any) => void;
  uri: string = '';
  timeout: number;
  maxRetryTimes: number;
  area: string;
  ignoreRetryWaiting: boolean = false;
  headers: object = { 'x-agc-nsp-js': 'JSSDK' };

  constructor(
    public storageManagement: StorageManagementImpl,
    public location: Location,
    public serverUrl: string,
    public method: string,
    area: string
  ) {
    this.timeout = storageManagement.maxRequestTimeout();
    this.maxRetryTimes = storageManagement.maxRetryTimes();
    this.ignoreRetryWaiting = storageManagement.ignoreRetryWaiting();
    this.area = area;
  }

  region(): string {
    return this.area;
  }

  sdkInfo(): SdkInfo {
    return cloudSDKInfo;
  }

  async header(): Promise<any> {
    return {
      'Content-Type': 'text/plain',
      'app_id': getAppConfig().app_id,
      ...this.headers
    };
  }

  async body(): Promise<any> {
    return Promise.resolve(this._body === undefined || this._body === '' ? {} : this._body);
  }

  url(): URL {
    const queryPart = UrlUtils.makeQueryString(this.urlParams);
    let config = CloudStorageConfig.getInstance();
    const urlInfo = config.getHostByRegion(this.area);
    const url = urlInfo.url + this.serverUrl + queryPart;
    return {
      main: url
    };
  }

  handle(res: any): T {
    return res;
  }
}

export interface Headers {
  [name: string]: string;
}
