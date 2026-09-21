// @keepTs
// @ts-nocheck
import { Chain, Interceptor } from "./k1";
import { Response } from "./u2";
import { SdkInfo } from "../w2/r2";
export declare class LoggerInterceptor implements Interceptor {
    region: string;
    sdkInfo: SdkInfo;
    constructor(region: string, sdkInfo: SdkInfo);
    intercept(chain: Chain): Promise<Response | null>;
}
