// @keepTs
// @ts-nocheck
import { BaseRequest, SdkInfo, URL } from "../../h1/i1/w2/r2";
export declare class AuthBaseRequest implements BaseRequest {
    region_: string;
    accessToken: string;
    protected readonly URL_PATH_PREFIX: string;
    protected URL_PATH_SURFFIX: string;
    constructor(region?: string);
    region(): string;
    sdkInfo(): SdkInfo;
    url(): URL;
    header(): Promise<Record<string, string>>;
    body(): Promise<Record<string, object | string | number>>;
    queryParam(): string;
}
