import {
  LowCode,
  DataModelOptions,
  DataModelResponse,
  InvokeOptions,
  InvokeResponse,
  LowCodeCommonResult
} from '../index';
import { ConnectorInvoker } from './connector/ConnectorInvoker';
import { DataModelInvoker } from './datamodel/DataModelInvoker';
import { CloudGlobalConfig } from '../../utils/CloudGlobalConfig';
import { CloudStorageCaller } from './cloudstorage/CloudStorageCaller';

export class LowCodeImpl implements LowCode {
  private config: CloudGlobalConfig;
  private connectorInvoker: ConnectorInvoker;
  private dataModelInvoker: DataModelInvoker;
  private cloudStorageCaller: CloudStorageCaller;

  constructor(config: CloudGlobalConfig) {
    this.config = config;
    this.connectorInvoker = new ConnectorInvoker();
    this.dataModelInvoker = new DataModelInvoker();
    this.cloudStorageCaller = new CloudStorageCaller();
  }

  callConnector(reqBody: InvokeOptions): Promise<LowCodeCommonResult<InvokeResponse>> {
    if (reqBody && typeof reqBody.connectorId === 'string' && reqBody.connectorId) {
      return this.connectorInvoker.invoke(reqBody, this.config);
    }
    return Promise.reject();
  }

  callDataModel(reqBody: DataModelOptions): Promise<LowCodeCommonResult<DataModelResponse>> {
    if (
      reqBody &&
      typeof reqBody.modelId === 'string' &&
      reqBody.modelId &&
      typeof reqBody.methodName === 'string' &&
      reqBody.methodName
    ) {
      return this.dataModelInvoker.invoke(reqBody, this.config);
    }
    return Promise.reject('');
  }

  getFileURL(fileIds: string | string[]): Promise<{ [key: string]: string }> {
    return this.cloudStorageCaller.getDownloadURLs(fileIds, this.config);
  }
}
