import { Chain, Interceptor } from './Interceptor';
import { Response } from './Response';
import { Logger } from '../log/Logger';

export class BackupInterceptor implements Interceptor {
  mainUrl: string;
  backUrl: string;

  constructor(mainUrl: string, backUrl: string) {
    this.mainUrl = mainUrl;
    this.backUrl = backUrl;
  }

  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    let resp = await chain.proceed(request);
    // 当前地址为主地址，并且主备不一致时
    if (request.url === this.mainUrl && this.mainUrl != this.backUrl) {
      if (resp && resp?.responseCode === 2300006) {
        Logger.warn('BackupInterceptor', 'use backup url.');
        request.url = this.backUrl;
        return chain.proceed(request);
      }
    }

    return resp;
  }
}
