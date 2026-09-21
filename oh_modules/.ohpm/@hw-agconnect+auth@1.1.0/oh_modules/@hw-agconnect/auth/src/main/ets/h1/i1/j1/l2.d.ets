// @keepTs
// @ts-nocheck
import { Chain, Interceptor } from "./k1";
import { Response } from "./u2";
export declare class CallServerInterceptor implements Interceptor {
    intercept(chain: Chain): Promise<Response>;
}
