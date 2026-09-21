import { Interceptor, Chain, Response } from '@hw-agconnect/hmcore';

export default class RefreshAccessTokenInterceptor implements Interceptor {
  intercept(chain: Chain): Promise<Response> {
    throw new Error('Method not implemented.');
  }
}
