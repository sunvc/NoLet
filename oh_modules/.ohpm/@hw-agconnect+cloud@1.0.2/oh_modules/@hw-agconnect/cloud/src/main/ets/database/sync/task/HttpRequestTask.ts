/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { MessageType } from '../utils/MessageType';
import { HttpsClient, HttpMethod } from '../../communicator/https/HttpsClient';
import { ProtoHelper, SerializeType } from '../ProtoHelper';
import { Utils } from '../../utils/Utils';
import { ExceptionUtil } from '../../utils/ExceptionUtil';
import { ErrorCode } from '../../utils/ErrorCode';
import { SyncResult } from '../request/SyncResult';
import { SyncRequest } from '../request/SyncRequest';
import { SyncTask } from './SyncTask';
import { CertificateService } from '../../security/CertificateService';

const TAG = 'HttpRequestTask';
const REQUEST_URL_MAP: Map<number, string> = new Map([
  [MessageType.SCHEMA_NEGOTIATE, '/negotiate'],
  [MessageType.OBJECT_UPDATE, '/upsert'],
  [MessageType.CACHE_UPDATE, '/upsert'],
  [MessageType.OBJECT_QUERY, '/query'],
  [MessageType.TRANSACTION, '/transaction'],
  [MessageType.ENCRYPTION_TASK, '/encryption']
]);

/**
 * HttpRequest
 *
 * success: request() -> onResponse() -> handle()
 * fail: request() -> handle()
 */
export class HttpRequestTask extends SyncTask {
  private static readonly httpResponseMap: Map<
    string,
    (ExceptionCode: ErrorCode, syncResult: SyncResult) => any
  > = new Map();

  private readonly certificateService: CertificateService;

  constructor(
    syncRequest: SyncRequest,
    keyVersion: number,
    certificateService: CertificateService,
    handle: (errorCode: ErrorCode, syncResult: SyncResult) => any
  ) {
    super();
    this.syncRequest = syncRequest;
    this.certificateService = certificateService;
    this.syncRequest.encryptionVersion = keyVersion;
    this.handle = handle;
  }

  request() {
    Logger.info(
      TAG,
      `[request] taskId:${this.syncRequest.taskId} \
            requestType: ${this.syncRequest.requestType} encryptType: ${this.syncRequest.requestSubType}`
    );
    const requestURL = REQUEST_URL_MAP.get(this.syncRequest.requestType);
    HttpRequestTask.httpResponseMap.set(this.syncRequest.taskId.toString(), this.handle);
    if (!requestURL) {
      Logger.warn(TAG, 'request: requestType is not contained in REQUEST_URL_MAP!');
      return;
    }
    new HttpsClient(this.certificateService).send(
      `${requestURL.toString()}?_v=${SerializeType.PROTOBUF}`,
      HttpMethod.POST,
      ProtoHelper.serializeMessage(this.syncRequest, this.certificateService),
      (isSuccess: boolean, message: any) => {
        Logger.info(TAG, `[request] isSuccess: ${isSuccess}`);
        if (isSuccess) {
          if (Utils.isArrayBuffer(message)) {
            this.onResponse(message);
          } else {
            Logger.warn(TAG, `[request] Illegal http response content type = ${typeof message}`);
            Logger.warn(TAG, `${ExceptionUtil.build(ErrorCode.SYNC_RESPONSE_CONTENT_ILLEGAL)}`);
            HttpRequestTask.httpResponseMap
              .get(this.syncRequest.taskId.toString())
              ?.call(null, ErrorCode.SYNC_RESPONSE_CONTENT_ILLEGAL, new SyncResult());
            HttpRequestTask.httpResponseMap.delete(this.syncRequest.taskId.toString());
          }
        } else {
          HttpRequestTask.httpResponseMap
            .get(this.syncRequest.taskId.toString())
            ?.call(null, message.code, new SyncResult());
          HttpRequestTask.httpResponseMap.delete(this.syncRequest.taskId.toString());
        }
      }
    );
  }

  onResponse(message: any) {
    const response = ProtoHelper.deserializeMessage(message);
    if (response.responseCode !== ErrorCode.OK) {
      Logger.warn(TAG, `[onResponse] CloudSyncResultCode = ${response.responseCode}`);
    }
    Logger.info(
      TAG,
      `[onResponse] taskId: ${response.taskId} responseType: ${response.type} \
            httpResponseMap size: ${HttpRequestTask.httpResponseMap.size}`
    );
    if (HttpRequestTask.httpResponseMap.has(response.taskId.toString())) {
      HttpRequestTask.httpResponseMap
        .get(response.taskId.toString())
        ?.call(null, response.responseCode as ErrorCode, response);
      HttpRequestTask.httpResponseMap.delete(response.taskId.toString());
    } else {
      Logger.warn(TAG, '[onResponse]: callback of the taskId has no register');
    }
  }
}
