// @keepTs
// @ts-nocheck
import List from '@ohos.util.List';
import { Chain, Interceptor } from "./k1";
import { Request } from "./v2";
import { Response } from "./u2";
export declare class RealInterceptorChain implements Chain {
    interceptors: List<Interceptor>;
    request_: Request;
    index: number;
    constructor(interceptors: List<Interceptor>, index: number, request: Request);
    request(): Request;
    proceed(request: Request): Promise<Response | null>;
}
