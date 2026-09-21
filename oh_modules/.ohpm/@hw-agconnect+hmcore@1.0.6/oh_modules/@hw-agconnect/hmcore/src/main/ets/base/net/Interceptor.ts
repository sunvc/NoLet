import { Request } from './Request';
import { Response } from './Response';

export interface Interceptor {
  intercept(chain: Chain): Promise<Response>;
}

export interface Chain {
  request(): Request;

  proceed(request: Request): Promise<Response>;
}
