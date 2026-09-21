// @keepTs
// @ts-nocheck
import http from "@ohos.net.http";
export declare class Request {
    url: string | undefined;
    method: http.RequestMethod | undefined;
    header: Record<string, string | object | number> | undefined;
    body: Record<string, string | object | number> | undefined;
    readTimeout?: number;
    connectTimeout?: number;
}
