import { Interceptor } from '@hw-agconnect/hmcore';
import { Chain } from '@hw-agconnect/hmcore';
import { Response } from '@hw-agconnect/hmcore';
import { AuthDefaultUser } from '../user/AuthDefaultUser';

export class AuthTokenInterceptor implements Interceptor {
  private user: AuthDefaultUser;

  constructor(user: AuthDefaultUser) {
    this.user = user;
  }

  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    try {
      if (!request.header) {
        request.header = {};
      }
      let token = await this.user.getToken(false);
      request.header['access_token'] = token?.getString();
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
