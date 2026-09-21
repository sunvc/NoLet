// @keepTs
// @ts-nocheck
/**
 * 上层业务实现该接口
 */
export interface BaseRequest {
    region(): string;
    sdkInfo(): SdkInfo;
    url(): URL;
    header(): Promise<Record<string, string | object | number>>;
    body(): Promise<Record<string, string | object | number>>;
}
export interface SdkInfo {
    sdkServiceName: string;
    sdkVersion: string;
}
export interface URL {
    main: string;
    back?: string;
}
