// @keepTs
// @ts-nocheck
import { Chain, Interceptor } from "./k1";
import { Response } from "./u2";
export declare class ClientTokenInterceptor implements Interceptor {
    region: string;
    constructor(region: string);
    intercept(chain: Chain): Promise<Response | null>;
}
