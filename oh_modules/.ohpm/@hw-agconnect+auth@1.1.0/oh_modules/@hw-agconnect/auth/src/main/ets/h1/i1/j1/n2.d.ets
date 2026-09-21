// @keepTs
// @ts-nocheck
import { Chain, Interceptor } from "./k1";
import { Response } from "./u2";
export declare class BackupInterceptor implements Interceptor {
    mainUrl: string;
    backUrl: string;
    constructor(mainUrl: string, backUrl: string);
    intercept(chain: Chain): Promise<Response | null>;
}
