// @keepTs
// @ts-nocheck
import { BaseRequest, SdkInfo, URL } from "../w2/r2";
export declare class ClientTokenRequest implements BaseRequest {
    interfaceId: string;
    region_: string;
    constructor(region?: string);
    sdkInfo(): SdkInfo;
    region(): string;
    url(): URL;
    header(): Promise<Record<string, string>>;
    body(): Promise<Record<string, string | number>>;
}
