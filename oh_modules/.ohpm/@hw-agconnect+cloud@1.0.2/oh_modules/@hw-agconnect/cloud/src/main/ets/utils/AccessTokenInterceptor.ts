import { Interceptor } from '@hw-agconnect/hmcore';
import { Chain } from '@hw-agconnect/hmcore';
import { Response } from '@hw-agconnect/hmcore';
import { AuthService } from './CloudGlobalConfig';
import { AGCAuthError } from '../auth/exception/AGCAuthError';
import { AGCAuthErrorCode } from '../auth/exception/AGCAuthErrorCode';

export interface Args {
  auth?: AuthService;
  isForceCheck?: boolean;
  isForceRefresh?: boolean;
  headerKey?: string;
}

export default class AccessTokenInterceptor implements Interceptor {
  private auth: AuthService;
  private isForceCheck: boolean;
  private isForceRefresh: boolean;
  private headerKey: string;

  constructor(args: Args) {
    this.auth = args.auth;
    this.isForceCheck = args.isForceCheck == null ? true : args.isForceCheck;
    this.isForceRefresh = args.isForceRefresh == null ? false : args.isForceRefresh;
    this.headerKey = args.headerKey == null ? 'access_token' : args.headerKey;
  }

  async intercept(chain: Chain): Promise<Response> {
    let request = chain.request();
    try {
      if (!request.header) {
        request.header = {};
      }
      let user = await this.auth().getCurrentUser();
      if (user == null) {
        if (this.isForceCheck) {
          return Promise.reject(new AGCAuthError(AGCAuthErrorCode.FAIL_TO_GET_ACCESS_TOKEN));
        } else {
          return chain.proceed(request);
        }
      } else {
        let token = await user.getToken(this.isForceRefresh);
        request.header[this.headerKey] = token?.getString();
        return chain.proceed(request);
      }
    } catch (e) {
      let resp = {
        responseCode: e?.code,
        message: e?.message
      };
      return Promise.resolve(resp);
    }
  }
}
