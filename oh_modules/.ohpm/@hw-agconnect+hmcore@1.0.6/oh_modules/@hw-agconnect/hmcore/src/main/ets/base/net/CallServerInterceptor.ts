import { Chain, Interceptor } from './Interceptor';
import { Response } from './Response';
import http from '@ohos.net.http';

export class CallServerInterceptor implements Interceptor {
  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    let connectTimeout = request.connectTimeout ? request.connectTimeout : 60000;
    let readTimeout = request.readTimeout ? request.readTimeout : 60000;
    let httpRequest = http.createHttp();
    let ohosOptions = {
      method: request.method,
      header: request.header,
      extraData: request.body,
      connectTimeout: connectTimeout,
      readTimeout: readTimeout
    };
    let resp;
    try {
      resp = await httpRequest.request(request.url, ohosOptions);
    } catch (e) {
      resp = {
        responseCode: e?.code,
        message: e?.message
      };
    }
    httpRequest.destroy();
    return Promise.resolve(resp);
  }
}
