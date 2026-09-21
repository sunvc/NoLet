// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./m/y3";
import List from '@ohos.util.List';
import { Interceptor } from "../h1/i1/j1/k1";
import { BaseResponse } from "../h1/i1/w2/z2";
import { Method } from "../h1/i1/w2/x2";
export declare class AuthBackend {
    constructor();
    get(request: AuthBaseRequest, responseClass: BaseResponse, interceptors?: List<Interceptor>): Promise<BaseResponse>;
    post(request: AuthBaseRequest, responseClass: BaseResponse, interceptors?: List<Interceptor>): Promise<BaseResponse>;
    put(request: AuthBaseRequest, responseClass: BaseResponse, interceptors?: List<Interceptor>): Promise<BaseResponse>;
    sendRequest(method: Method, request: AuthBaseRequest, responseClass: BaseResponse, interceptors?: List<Interceptor>): Promise<BaseResponse>;
}
