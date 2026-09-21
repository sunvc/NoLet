import { BaseRequest, SdkInfo, URL, getAppConfig, getGrsConfig } from '@hw-agconnect/hmcore';
import { cloudSDKInfo } from '../../utils/SDKInfo';
import { hash } from '../util/HashUtil';
import { GRS_TYPE } from '@hw-agconnect/hmcore';

export class FunctionRequest implements BaseRequest {
  private REQUEST_URL: string = '/agc/apigw/wisefunction/functions';

  _region: string;
  _httpTriggerURI: string;
  _params: any;
  _urlPath: string;

  constructor(region: string, name: string, version?: string, params?: any) {
    this._region = region;
    this._params = (params == undefined || params == null || params == '') ? {} : params;
    this._httpTriggerURI = jointHttpTriggerURI(name, version);
    this._urlPath = '';
  }

  region(): string {
    return this._region;
  }

  sdkInfo(): SdkInfo {
    return cloudSDKInfo;
  }

  url(): URL {
    return {
      main: 'https://' + getGrsConfig(GRS_TYPE.AGC_GW, this._region) + this._urlPath,
      back: 'https://' + getGrsConfig(GRS_TYPE.AGC_GW_BACK, this._region) + this._urlPath
    };
  }

  header(): Promise<any> {
    return null;
  }

  body(): Promise<any> {
    return this._params;
  }

  async prepareUrlPath() {
    let teamId: string = getAppConfig().cp_id;
    let productId: string = getAppConfig().product_id;
    let formatStr: string = 'agc:' + teamId + '@' + productId;
    let appId: string = await hash(formatStr);

    this._urlPath = this.REQUEST_URL + '/' + appId + this._httpTriggerURI;
  }
}

export class FunctionLocalRequest implements BaseRequest {
  _region: string;
  _params: any;
  _url: string;

  constructor(region: string, emulatorUrl: string, name: string, params?: any) {
    this._region = region;
    this._params = params === undefined || params === '' ? {} : params;

    if (emulatorUrl.charAt(emulatorUrl.length - 1) == '/') {
      this._url = emulatorUrl + name + '/invoke';
    } else {
      this._url = emulatorUrl + '/' + name + '/invoke';
    }
  }

  region(): string {
    return this._region;
  }

  sdkInfo(): SdkInfo {
    return cloudSDKInfo;
  }

  url(): URL {
    return {
      main: this._url
    };
  }

  header(): Promise<any> {
    return null;
  }

  body(): Promise<any> {
    return this._params;
  }
}

function jointHttpTriggerURI(name: string, version?: string): string {
  let httpTriggerURI: string = null;
  if (name && name.length >= 0 && name.charAt(0) != '/') {
    httpTriggerURI = '/' + name;
  } else {
    httpTriggerURI = name;
  }

  if (version) {
    httpTriggerURI = httpTriggerURI + '-' + version;
  } else {
    httpTriggerURI = httpTriggerURI + '-' + '$latest';
  }

  return httpTriggerURI;
}
