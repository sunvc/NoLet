import { DataModelOptions, DataModelType, DataModelResponse, LowCodeCommonResult } from '../..';
import { callFunction } from '../../../function/server/FunctionBackend';
import { CloudGlobalConfig } from '../../../utils/CloudGlobalConfig';
import { LowCodeCommonResultImpl } from '../LowCodeCommonResultImpl';

const DRAFT_MODEL_FUNCTION_NAME: string = 'lowcode-draft-model-instance';
const RELEASE_MODEL_FUNCTION_NAME: string = 'lowcode-release-model-instance';

export class DataModelInvoker {
  async invoke(
    reqBody: DataModelOptions,
    config: CloudGlobalConfig
  ): Promise<LowCodeCommonResult<DataModelResponse>> {
    let functionName = this.getFunctionName(reqBody.status);
    if (functionName == undefined) {
      return Promise.reject('');
    }
    let functionReq = {
      operationType: reqBody.methodName,
      modelId: reqBody.modelId,
      param: reqBody.params ? reqBody.params : {}
    };
    (functionReq.param! as any).modelId = reqBody.modelId;

    let functionResult = await callFunction(
      {
        name: functionName,
        version: reqBody.version,
        timeout: reqBody.timeout,
        params: functionReq
      },
      config
    );
    let invokeConnectorResult = new LowCodeCommonResultImpl();
    invokeConnectorResult.constructResponse(functionResult.getValue());
    return invokeConnectorResult as LowCodeCommonResult<DataModelResponse>;
  }

  getFunctionName(type: DataModelType): string | undefined {
    let functionName = undefined;
    switch (type) {
      case DataModelType.DRAFT:
        functionName = DRAFT_MODEL_FUNCTION_NAME;
        break;
      case DataModelType.RELEASE:
        functionName = RELEASE_MODEL_FUNCTION_NAME;
        break;
    }
    return functionName;
  }
}
