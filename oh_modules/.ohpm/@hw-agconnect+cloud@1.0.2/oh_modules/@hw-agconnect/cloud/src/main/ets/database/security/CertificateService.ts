/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { getGrsConfig, getAppConfig, getToken, GRS_TYPE, Logger } from '@hw-agconnect/hmcore';
import { ContextType } from '../sync/utils/EntityTemplate';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { ContextWrapper } from '../utils/ContextWrapper';
import { ConfigWrapper } from '../config/ConfigWrapper';

export type Context = {
  // client.product_id
  productId: string;
  // client.app_id
  appId: string;
  // client.client_id
  clientId: string;
  // client.cp_id
  userId: string;
  // schema.schema_version
  appVersion: number;
  clientVersion: number;
};

const TAG = 'CertificateService';

/**
 * @NOTE This class is the interface between JS SDK and AGC Auth.
 * We implement auth logic here.
 */
export class CertificateService {
  // used for initializing AGC Auth.
  private static readonly APP_VERSION = '003';

  private websocketUrl = '';
  private websocketBackUrl = '';
  private httpUrl = '';
  private httpBackUrl = '';
  private context!: Context;
  private region: string;

  public constructor(region: string) {
    this.region = region;

    this.loadAgcGwAddress();

    this.setContext();
  }

  static async getUserInfo() {
    return await ConfigWrapper.getConfigInstance().getCurrentUser();
  }

  static checkSupportEncryption(): void {
    throw ExceptionUtil.build(
      `${ContextWrapper.getApplicationType()} platform is not support encryption feature`
    );
  }

  /**
   * generate Bearer Token
   */
  private async getAuthorization() {
    const token = await getToken(false, this.region);
    return `Bearer ${token.tokenString}`;
  }

  public async getHeaderParam(isArrayBuffer?: boolean): Promise<Header> {
    const user = await ConfigWrapper.getConfigInstance().getCurrentUser();
    const tokenString = await this.getAuthorization();
    const header = this.createHeader(tokenString, isArrayBuffer);
    if (user) {
      const token = await user.getToken(false);
      header.access_token = this.escapeHeader(token.getToken())!;
    }
    return header;
  }

  private createHeader(tokenString: string, isArrayBuffer?: boolean): Header {
    return {
      'Content-Type': isArrayBuffer ? ContextType.PROTO_BUF : ContextType.JSON,
      authorization: this.escapeHeader(tokenString),
      client_id: this.escapeHeader(this.context.clientId)!,
      productId: this.escapeHeader(this.context.productId)!,
      sdkPlatform: ContextWrapper.getApplicationType(),
      sdkVersion: ContextWrapper.getApplicationVersion(),
      appVersion: CertificateService.APP_VERSION
    };
  }

  private escapeHeader(value: string) {
    return value?.replace(/^\w /g, '');
  }

  private loadAgcGwAddress() {
    this.websocketUrl = `wss://${getGrsConfig(
      GRS_TYPE.WEBSOCKET_GW,
      this.region
    )}/agc/websocket/connection`;
    this.websocketBackUrl = `wss://${getGrsConfig(
      GRS_TYPE.WEBSOCKET_GW_BACK,
      this.region
    )}/agc/websocket/connection`;
    this.httpUrl = `https://${getGrsConfig(
      GRS_TYPE.AGC_GW,
      this.region
    )}/agc/apigw/clouddb/clouddbservice/sync`;
    this.httpBackUrl = `https://${getGrsConfig(
      GRS_TYPE.AGC_GW_BACK,
      this.region
    )}/agc/apigw/clouddb/clouddbservice/sync`;
  }

  public setAppVersion(version: number) {
    this.context.appVersion = version;
  }

  public getSubscribeOptions() {
    return {
      url: this.websocketUrl
    };
  }

  public getSubscribeBackOptions() {
    return {
      url: this.websocketBackUrl
    };
  }

  public getContext(): Context {
    return this.context;
  }

  public getUrl(): string {
    return this.httpUrl;
  }

  public getBackUrl(): string {
    return this.httpBackUrl;
  }

  private setContext() {
    let appConfig = getAppConfig();
    this.context = {
      productId: appConfig?.product_id,
      appId: appConfig?.app_id,
      clientId: appConfig?.client_id,
      userId: appConfig?.cp_id,
      appVersion: 0,
      clientVersion: 2
    };
  }
}

interface Header {
  'Content-Type': ContextType;
  authorization: string;
  client_id: string;
  productId: string;
  access_token?: string;
  sdkPlatform: string;
  sdkVersion: string;
  appVersion: string;
}
