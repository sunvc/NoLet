import List from '@ohos.util.List';
import http from '@ohos.net.http';
import { CallServerInterceptor } from '../base/net/CallServerInterceptor';
import { Interceptor } from '../base/net/Interceptor';
import { RealInterceptorChain } from '../base/net/RealInterceptorChain';
import { BackupInterceptor } from '../base/net/BackupInterceptor';
import { ClientTokenInterceptor } from '../base/net/ClientTokenInterceptor';
import { AGCError } from '../error/AGCError';
import { BaseRequest } from './BaseRequest';
import { ApiInterceptor } from '../base/net/ApiInterceptor';
import { LoggerInterceptor } from '../base/net/LoggerInterceptor';

export class Backend {
  static async post(
    request: BaseRequest,
    options?: HttpOptions,
    interceptors?: List<Interceptor>
  ): Promise<any> {
    return this.sendRequest('POST', request, options, interceptors);
  }

  static async sendRequest(
    method: Method,
    baseRequest: BaseRequest,
    options?: HttpOptions,
    interceptors?: List<Interceptor>
  ): Promise<any> {
    let list: List<Interceptor> = new List();
    if (interceptors && interceptors.length > 0) {
      list = interceptors;
    }

    list.add(new LoggerInterceptor(baseRequest.region(), baseRequest.sdkInfo()));
    if (baseRequest.url().back) {
      list.add(new BackupInterceptor(baseRequest.url().main, baseRequest.url().back));
    }

    if (options && options.clientToken) {
      list.add(new ClientTokenInterceptor(baseRequest.region()));
    }
    list.add(new ApiInterceptor(baseRequest.sdkInfo()));
    list.add(new CallServerInterceptor());

    let request_ = {
      url: baseRequest.url().main,
      method: method as http.RequestMethod,
      header: await baseRequest.header(),
      body: await baseRequest.body(),
      readTimeout: options?.readTimeout,
      connectTimeout: options?.connectTimeout
    };

    let realInterceptorChain = new RealInterceptorChain(list, 0, request_);
    let response = await realInterceptorChain.proceed(request_);
    if (response && response.responseCode == 200) {
      return Promise.resolve(response.result);
    } else {
      let message = response?.message;
      if (!message) {
        message = response?.result?.toString();
      }
      return Promise.reject(new AGCError(response?.responseCode, message));
    }
  }
}

export interface HttpOptions {
  clientToken?: boolean;
  readTimeout?: number;
  connectTimeout?: number;
}

export type Method = 'GET' | 'POST' | 'PUT' | 'DELETE';
