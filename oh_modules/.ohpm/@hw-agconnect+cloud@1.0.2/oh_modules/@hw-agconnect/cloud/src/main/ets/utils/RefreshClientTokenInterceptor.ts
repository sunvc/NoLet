import { Interceptor, Chain, Response } from '@hw-agconnect/hmcore';

export default class RefreshClientTokenInterceptor implements Interceptor {
  _region: string;
  constructor(region: string) {
    this._region = region;
  }

  intercept(chain: Chain): Promise<Response> {
    throw new Error('Method not implemented.');
  }
}
