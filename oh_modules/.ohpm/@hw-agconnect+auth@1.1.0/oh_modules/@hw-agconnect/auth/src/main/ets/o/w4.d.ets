// @keepTs
// @ts-nocheck
import { Chain, Interceptor } from "../h1/i1/j1/k1";
import { Response } from "../h1/i1/j1/u2";
import { AuthDefaultUser } from "../k/x4";
export declare class AuthTokenInterceptor implements Interceptor {
    private user;
    constructor(user: AuthDefaultUser);
    intercept(chain: Chain): Promise<Response | null>;
}
