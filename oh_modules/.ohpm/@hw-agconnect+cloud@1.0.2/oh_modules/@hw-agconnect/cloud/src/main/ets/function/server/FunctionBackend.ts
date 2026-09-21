import { Backend, HttpOptions, Interceptor } from '@hw-agconnect/hmcore';
import { FunctionOptions } from '../index';
import { FunctionRequest, FunctionLocalRequest } from './FunctionRequest';
import { FunctionResponse } from './FunctionResponse';
import AccessTokenInterceptor from '../../utils/AccessTokenInterceptor';
import List from '@ohos.util.List';
import { CloudGlobalConfig } from '../../utils/CloudGlobalConfig';

export async function callFunction(options: FunctionOptions, globalConfig: CloudGlobalConfig) {
  if (options.emulatorUrl) {
    let request = new FunctionLocalRequest(
      globalConfig.region,
      options.emulatorUrl,
      options.name,
      options.params
    );

    let response = await Backend.post(request);
    return new FunctionResponse(response);
  }

  let request = new FunctionRequest(
    globalConfig.region,
    options.name,
    options.version,
    options.params
  );
  await request.prepareUrlPath();

  let timeout = options.timeout ? options.timeout : 70000;
  let httpOption: HttpOptions = {
    clientToken: true,
    readTimeout: timeout,
    connectTimeout: timeout
  };

  let atInterceptor = new AccessTokenInterceptor({
    auth: globalConfig.auth,
    isForceCheck: false,
    headerKey: 'accessToken'
  });

  let list: List<Interceptor> = new List();
  list.add(atInterceptor);
  let response = await Backend.post(request, httpOption, list);
  return new FunctionResponse(response);
}
