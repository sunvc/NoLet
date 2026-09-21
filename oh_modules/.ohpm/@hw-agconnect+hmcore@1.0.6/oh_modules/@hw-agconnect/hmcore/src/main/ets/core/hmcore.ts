import common from '@ohos.app.ability.common';
import { error, CoreErrorCode } from '../error/CoreErrorCode';
import { AppConfig, getRegion, GRS_TYPE, JsonTypeInfo } from '../core';
import Aaid from '../base/aaid/Aaid';
import Credential from '../credential/Credentia';
import { Logger } from '../base/log/Logger';
import { replace } from './ConfigFileParser';
import { DecryptExclamationMark } from './DecryptExclamationMark';

const TAG = 'hmcore';

export function getCore(): Core {
  if (!globalThis.agconnect_hmcore) {
    throw error(
      CoreErrorCode.INIT_ERROR,
      'agconnect sdk not initialized. please call initialize().'
    );
  }
  return globalThis.agconnect_hmcore;
}

export function createCore(applicationContext: common.Context, json: JsonTypeInfo) {
  if (!applicationContext) {
    throw error(CoreErrorCode.INIT_ERROR, 'init context error.');
  }
  if (!json) {
    throw error(CoreErrorCode.INIT_ERROR, 'init JsonTypeInfo error.');
  }

  if (globalThis.agconnect_hmcore) {
    Logger.info(TAG, 'repeat initialized, ignore.');
    return;
  }
  globalThis.agconnect_hmcore = new Core(applicationContext, json);
}

export class Core {
  private applicationContext_;
  private json_;
  private appConfig_: AppConfig;
  private apiKey;
  private clientSecret;

  private decryptMark: DecryptExclamationMark | undefined;

  constructor(applicationContext: common.Context, json: JsonTypeInfo) {
    this.applicationContext_ = applicationContext;
    if (applicationContext?.getApplicationContext()) {
      this.applicationContext_ = applicationContext?.getApplicationContext();
    }
    let packageName = this.applicationContext_.applicationInfo?.name;
    this.json_ = replace(packageName, json);
  }

  get context() {
    return this.applicationContext_;
  }

  get region(): string {
    return this.json_.region;
  }

  async getApiKey(): Promise<string> {
    if (this.apiKey) {
      return this.apiKey;
    }
    this.apiKey = await this.getDecryptString('/client/api_key');
    return this.apiKey;
  }

  setApikey(apiKey: string) {
    this.apiKey = apiKey;
  }

  async getClientSecret(): Promise<string> {
    if (this.clientSecret) {
      return this.clientSecret;
    }
    this.clientSecret = await this.getDecryptString('/client/client_secret');
    return this.clientSecret;
  }

  setClientSecret(clientSecret: string) {
    this.clientSecret = clientSecret;
  }

  aaid(): Promise<string> {
    return Aaid.get(this.applicationContext_);
  }

  token(refresh?: boolean, region?: string) {
    if (!refresh) {
      refresh = false;
    }
    if (!region) {
      region = getRegion();
    }
    return Credential.getToken(refresh, region);
  }

  get appConfig(): AppConfig {
    if (!this.appConfig_) {
      this.appConfig_ = {
        cp_id: this.json_.client?.cp_id,
        product_id: this.json_.client?.product_id,
        client_id: this.json_.client?.client_id,
        project_id: this.json_.client?.project_id,
        app_id: this.json_.client?.app_id,
        package_name: this.json_.client?.package_name
      };
    }
    return this.appConfig_;
  }

  getGrsConfig(type: GRS_TYPE, region?: string): string {
    if (!region) {
      region = this.region;
    }
    switch (type) {
      case GRS_TYPE.AGC_GW:
        return this.getString(`/agcgw_all/${region}`);
      case GRS_TYPE.AGC_GW_BACK:
        return this.getString(`/agcgw_all/${region}_back`);
      case GRS_TYPE.WEBSOCKET_GW:
        return this.getString(`/websocketgw_all/${region}`);
      case GRS_TYPE.WEBSOCKET_GW_BACK:
        return this.getString(`/websocketgw_all/${region}_back`);
      case GRS_TYPE.STORAGE_GW:
        return this.getString(`/service/cloudstorage/storage_url_${region.toLowerCase()}`);
      case GRS_TYPE.STORAGE_GW_BACK:
        return this.getString(`/service/cloudstorage/storage_url_${region.toLowerCase()}_back`);
    }
  }

  private async getDecryptString(path: string): Promise<string> {
    let originalValue = this.getString(path);
    if (DecryptExclamationMark.isMatch(originalValue)) {
      if (!this.decryptMark) {
        this.decryptMark = new DecryptExclamationMark(
          this.json_['code']['code1'],
          this.json_['code']['code2'],
          this.json_['code']['code3'],
          this.json_['code']['code4']
        );
      }
      let decrypt = await this.decryptMark.decrypt(originalValue);
      if (decrypt) {
        return decrypt;
      }
    }
    return originalValue;
  }

  getString(path: string): string {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    let array = path.split('/');
    let value = this.json_;
    for (let key = 0; key < array.length; key++) {
      value = value[array[key]];
    }
    return value;
  }
}
