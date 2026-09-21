// @keepTs
// @ts-nocheck
import { Chain, Interceptor } from "./k1";
import { Response } from "./u2";
import { SdkInfo } from "../w2/r2";
export declare class ApiInterceptor implements Interceptor {
    sdkInfo: SdkInfo;
    constructor(sdkInfo: SdkInfo);
    apiInfo(): Promise<Record<string, string | number>>;
    intercept(chain: Chain): Promise<Response | null>;
}
