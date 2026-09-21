import http from '@ohos.net.http';

export class Request {
  url: string;
  method: http.RequestMethod;
  header: any;
  body?: string | Object | ArrayBuffer;
  readTimeout?: number;
  connectTimeout?: number;
}
