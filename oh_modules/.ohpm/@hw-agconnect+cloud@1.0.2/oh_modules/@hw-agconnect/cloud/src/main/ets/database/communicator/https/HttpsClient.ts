/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { OHHttpsAdapter } from './adapter/OHHttpsAdapter';
import { CertificateService } from '../../security/CertificateService';
import { Utils } from '../../utils/Utils';
import { ExceptionUtil } from '../../utils/ExceptionUtil';
import { ErrorCode } from '../../utils/ErrorCode';
import { HttpsAdapter } from './adapter/HttpsAdapter';

const ERROR_CODE_REQUEST_ENTITY_TOO_LARGE = 413;

export const enum HttpMethod {
  POST = 'POST',
  GET = 'GET',
  DELETE = 'DELETE',
  PUT = 'PUT'
}

const TAG = 'HttpsClient';

export class HttpsClient {
  private productId: string;
  private certificateService: CertificateService;
  private httpAdapter: HttpsAdapter;

  constructor(certificateService: CertificateService) {
    this.productId = '';
    this.certificateService = certificateService;
    this.httpAdapter = new OHHttpsAdapter();
  }

  async send(
    path: string,
    method: HttpMethod,
    param: object,
    callback: (flag: boolean, reason: any) => void
  ) {
    if (Utils.isEmpty(this.certificateService.getContext())) {
      callback(false, ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID));
      return;
    }
    this.productId = this.certificateService.getContext().productId;
    const isInvalid = !this.productId;
    if (isInvalid) {
      callback(false, ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID));
      return;
    }
    await this.processRequest(
      this.certificateService.getUrl() + path,
      this.certificateService.getBackUrl() + path,
      method,
      param,
      callback
    );
  }

  private async processRequest(
    path: string,
    backPath: string,
    method: HttpMethod,
    param: object,
    callback: (flag: boolean, reason: any) => void
  ) {
    const isArrayBuffer: boolean = param instanceof ArrayBuffer;
    const data = isArrayBuffer ? param : JSON.stringify(param);
    try {
      const headers = await this.certificateService.getHeaderParam(isArrayBuffer);
      if (headers === undefined) {
        callback(false, ExceptionUtil.build(ErrorCode.USER_INFO_REQUEST_ERROR));
        return;
      }
      this.requestForSync(path, backPath, method, data, headers, callback);
    } catch (e) {
      callback(false, ExceptionUtil.build(ErrorCode.GATE_COMM_OVER_TIME));
      return;
    }
  }

  private requestForSync(
    path: string,
    backPath: string,
    method: HttpMethod,
    data: any,
    headers: any,
    callback: (flag: boolean, reason: any) => void
  ) {
    const req = {
      url: path,
      backUrl: backPath,
      method,
      header: headers,
      data,
      success: (res: any) => {
        callback(true, res.data);
        Logger.info(TAG, 'requestForSync: success!');
      },
      fail: (errorInfo: any) => {
        Logger.error(TAG, `HTTPS request process failed.`);
        if (errorInfo.status === ERROR_CODE_REQUEST_ENTITY_TOO_LARGE) {
          Logger.error(TAG, `Request entity is too large.`);
          const exception = ExceptionUtil.build(ErrorCode.COMMUNICATOR_DATA_LENGTH_INVALID);
          callback(false, exception);
          return;
        }
        callback(false, ExceptionUtil.build(ErrorCode.GATE_COMM_OVER_TIME));
      }
    };
    Logger.info(TAG, 'HTTP_ADAPTER send request');
    this.httpAdapter.request(req);
  }
}
