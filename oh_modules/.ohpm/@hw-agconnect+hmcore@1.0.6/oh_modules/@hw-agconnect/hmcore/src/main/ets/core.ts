import common from '@ohos.app.ability.common';
import { createCore, getCore } from './core/hmcore';

/**
 * 初始化AGC SDK
 * @param applicationContext ohos应用的applicationContext
 * @param json  agconnect-services.json文件内容。
 */
export function initialize(applicationContext: common.Context, json: JsonTypeInfo) {
  createCore(applicationContext, json);
}

/**
 * 获取初始化的applicationContext
 */
export function getContext(): common.Context {
  return getCore().context;
}

/**
 * 获取默认的存储地
 */
export function getRegion(): Region {
  return getCore().region as Region;
}

/**
 * 获取应用的aaid
 */
export function getAaid(): Promise<string> {
  return getCore().aaid();
}

/**
 * 获取AGC网关认证凭据
 * @param refresh 是否强制刷新token，【可选】，默认为false
 * @param region  储存地信息，【可选】，默认为【getRegion()】
 */
export function getToken(refresh?: boolean, region?: string): Promise<Token> {
  return getCore().token(refresh, region);
}

export function getAppConfig(): AppConfig {
  return getCore().appConfig;
}

export function getGrsConfig(type: GRS_TYPE, region?: string) {
  return getCore().getGrsConfig(type, region);
}

/**
 * 获取agconnect-services.json具体的配置项
 * @param path 配置项在 agconnect-services.json 文件中的位置，用'/'分隔。
 * 比如：
 * 1.获取client_id：client.client_id：调用方式getString('/client/client_id')
 * 2.获取client_secret：client.client_secret：调用方式getString('/client/client_secret'),获取的client_secret为最终的解密后的数据。
 * 2.获取collector_url_cn：service.analytics.collector_url_cn：调用方式getString('/service/analytics/collector_url_cn'),
 */
export function getString(path: string): any {
  return getCore().getString(path);
}

/**
 * 获取config对象的client_secret
 * 如果开发者调用了'setClientSecret()',获取的将是开发者设置的值,
 * 如果开发者没有调用'setClientSecret()'，获取到的将是有sdk解析出来的agconnect-services.json对应路径的数据值（与getString('/client/client_secret')功能相同）。
 */
export function getClientSecret(): Promise<string> {
  return getCore().getClientSecret();
}

/**
 * 手动设置SDK鉴权秘钥。
 * 如果开发者下载包含秘钥版本的agconnect-services.json ,此方法无需开发者手动调用，
 * 如果开发者下载未包含钥版本的agconnect-services.json，需要开发者调用此接口，设置SDK鉴权秘钥
 * @param clientSecret 获取方式：登录AGC控制台->项目设置->项目->客户端ID->Client Secret
 */
export function setClientSecret(clientSecret: string) {
  getCore().setClientSecret(clientSecret);
}

/**
 * 获取config对象的api_key
 * 如果开发者调用了'setApiKey()',获取的将是开发者设置的值,
 * 如果开发者没有调用'setApiKey()'，获取到的将是有sdk解析出来的agconnect-services.json对应路径的数据值（与getString('/client/api_key')功能相同）。
 */
export function getApiKey(): Promise<string> {
  return getCore().getApiKey();
}

/**
 * 设置API密钥
 * 如果开发者下载包含秘钥版本的agconnect-services.json ,此方法无需开发者手动调用，
 * 如果开发者下载未包含钥版本的agconnect-services.json，需要开发者调用此接口，设置API秘钥
 * @param apiKey 获取方式：登录AGC控制台->项目设置->项目->API密钥（凭据）
 */
export function setApiKey(apiKey: string) {
  getCore().setApikey(apiKey);
}

export type AppConfig = {
  cp_id: string;
  product_id: string;
  client_id: string;
  project_id: string;
  app_id: string;
  package_name: string;
};

export enum GRS_TYPE {
  AGC_GW,
  AGC_GW_BACK,
  WEBSOCKET_GW,
  WEBSOCKET_GW_BACK,
  STORAGE_GW,
  STORAGE_GW_BACK
}

export type JsonTypeInfo = {
  agcgw: any;
  agcgw_all: any;
  client: any;
  service: any;
  oauth_client?: any;
  app_info?: any;
  region: string;
  configuration_version: string;
  appInfos?: any;

  [string: string]: any;
};

export interface Token {
  expiration: number;
  tokenString: string;
}

export enum Region {
  CN = 'CN',
  DE = 'DE',
  RU = 'RU',
  SG = 'SG'
}
