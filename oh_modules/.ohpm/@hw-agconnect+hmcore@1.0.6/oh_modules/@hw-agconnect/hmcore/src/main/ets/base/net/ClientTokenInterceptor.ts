import { getToken } from '../../core';
import { Chain, Interceptor } from './Interceptor';
import { Response } from './Response';

export class ClientTokenInterceptor implements Interceptor {
  region: string;

  constructor(region: string) {
    this.region = region;
  }

  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    try {
      let token = await getToken(false, this.region);
      if (!request.header) {
        request.header = {};
      }
      request.header.Authorization = 'Bearer ' + token?.tokenString;
      return chain.proceed(request);
    } catch (e) {
      let resp = {
        responseCode: e?.code,
        message: e?.message
      };
      return Promise.resolve(resp);
    }
  }
}
