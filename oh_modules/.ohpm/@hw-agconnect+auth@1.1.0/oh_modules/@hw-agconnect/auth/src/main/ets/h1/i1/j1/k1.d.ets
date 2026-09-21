// @keepTs
// @ts-nocheck
import { Request } from "./v2";
import { Response } from "./u2";
export interface Interceptor {
    intercept(chain: Chain): Promise<Response | null>;
}
export interface Chain {
    request(): Request;
    proceed(request: Request): Promise<Response | null>;
}
