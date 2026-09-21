import { InvokeOptions, InvokeResponse, LowCodeCommonResult } from '../../index';
import { CloudGlobalConfig } from '../../../utils/CloudGlobalConfig';
import { LowCodeCommonResultImpl } from '../LowCodeCommonResultImpl';
import { callFunction } from '../../../function/server/FunctionBackend';

const CONNECTOR_INVOKE_FUNCTION_NAME: string = 'lowcode-connector-execution';

export class ConnectorInvoker {
  async invoke(
    reqBody: InvokeOptions,
    config: CloudGlobalConfig
  ): Promise<LowCodeCommonResult<InvokeResponse>> {
    let functionResult = await callFunction(
      {
        name: CONNECTOR_INVOKE_FUNCTION_NAME,
        version: reqBody.version,
        timeout: reqBody.timeout,
        params: {
          apiName: 'invoke',
          connectorId: reqBody.connectorId,
          methodName: reqBody.methodName,
          params: reqBody.params
        }
      },
      config
    );
    let invokeConnectorResult = new LowCodeCommonResultImpl();
    invokeConnectorResult.constructResponse(functionResult.getValue());
    return invokeConnectorResult as LowCodeCommonResult<InvokeResponse>;
  }
}
