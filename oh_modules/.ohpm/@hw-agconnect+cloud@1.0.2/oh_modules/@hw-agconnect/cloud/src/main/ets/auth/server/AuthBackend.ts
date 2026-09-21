import { Method } from '@hw-agconnect/hmcore';
import { Backend, BaseResponse } from '@hw-agconnect/hmcore';
import { AGCAuthError } from '../exception/AGCAuthError';
import { AuthBaseRequest } from './request/AuthBaseRequest';
import { Interceptor } from '@hw-agconnect/hmcore';
import List from '@ohos.util.List';

export class AuthBackend {
  async get<T>(
    request: AuthBaseRequest,
    responseClass: BaseResponse,
    interceptors?: List<Interceptor>
  ): Promise<BaseResponse> {
    return this.sendRequest('GET', request, responseClass, interceptors);
  }

  async post<T>(
    request: AuthBaseRequest,
    responseClass: BaseResponse,
    interceptors?: List<Interceptor>
  ): Promise<BaseResponse> {
    return this.sendRequest('POST', request, responseClass, interceptors);
  }

  async put<T>(
    request: AuthBaseRequest,
    responseClass: BaseResponse,
    interceptors?: List<Interceptor>
  ): Promise<BaseResponse> {
    return this.sendRequest('PUT', request, responseClass, interceptors);
  }

  async sendRequest(
    method: Method,
    request: AuthBaseRequest,
    responseClass: BaseResponse,
    interceptors?: List<Interceptor>
  ): Promise<BaseResponse> {
    let options = {
      clientToken: true
    };

    let response = await Backend.sendRequest(method, request, options, interceptors);
    let result = JSON.parse(response);
    if (result?.ret?.code == 0) {
      if (!responseClass.constructResponse(result)) {
        responseClass = result;
      }
      return responseClass;
    } else if (result?.ret?.code != 0) {
      let authErrorCode = {
        code: result.ret.code,
        message: result.ret.msg
      };
      return Promise.reject(new AGCAuthError(authErrorCode));
    } else {
      return Promise.reject(result);
    }
  }
}
