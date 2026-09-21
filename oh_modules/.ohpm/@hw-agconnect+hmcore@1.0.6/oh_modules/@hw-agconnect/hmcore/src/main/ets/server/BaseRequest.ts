/**
 * 上层业务实现该接口
 */
export interface BaseRequest {
  region(): string;

  sdkInfo(): SdkInfo;

  url(): URL;

  header(): Promise<any>;

  body(): Promise<any>;
}

export type SdkInfo = {
  sdkServiceName: string;
  sdkVersion: string;
};

export type URL = {
  main: string;
  back?: string;
};
