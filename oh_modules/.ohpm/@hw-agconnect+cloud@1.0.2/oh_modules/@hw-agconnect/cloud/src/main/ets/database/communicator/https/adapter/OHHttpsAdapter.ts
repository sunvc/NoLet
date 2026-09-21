/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { HTTP_STATUS_CODE, HttpsAdapter } from './HttpsAdapter';
import { HttpMethod } from '../HttpsClient';
import { OHHttpsClient } from './OHHttpsClient';

const TAG = 'OHHttpsAdapter';

export class OHHttpsAdapter extends HttpsAdapter {
  private httpClient = new OHHttpsClient();

  protected realRequest(object: any): void {
    const url = object.url;
    const backUrl = object.backUrl;
    const method = object.method;
    const header = object.header;
    const data = object.data;
    // eslint-disable-next-line no-empty-function,@typescript-eslint/no-empty-function
    const success = object.success ? object.success : (_: any) => {};
    // eslint-disable-next-line no-empty-function,@typescript-eslint/no-empty-function
    const fail = object.fail ? object.fail : (_: any) => {};
    this.internalRequest(url, method, header, data, (err: any, response: any) => {
      if (err) {
        const errorMsg = JSON.stringify(err);
        Logger.warn(TAG, `[Http Adapter fail] =>${errorMsg}`);
        fail(err);
        return;
      }
      const responseCode = response.responseCode;
      if (responseCode >= HTTP_STATUS_CODE.OK && responseCode < HTTP_STATUS_CODE.MULTIPLE_CHOICES) {
        success({
          statusCode: responseCode,
          data: response.result
        });
      } else {
        Logger.warn(TAG, `[Http Adapter fail] =>${responseCode} ${response.result}`);
        this.retryRequest(backUrl, method, header, data, success, fail);
      }
    }).catch((error: any) => {
      this.retryRequest(backUrl, method, header, data, success, fail);
    });
  }

  private internalRequest(
    url: string,
    method: string,
    header: any,
    data: any,
    callback: (err: any, result: any) => void
  ) {
    switch (method) {
      case HttpMethod.DELETE:
        return this.httpClient.request(url, HttpMethod.DELETE, callback, undefined, header);
      case HttpMethod.GET:
        return this.httpClient.request(url, HttpMethod.GET, callback, undefined, header);
      case HttpMethod.POST:
        return this.httpClient.request(url, HttpMethod.POST, callback, data, header);
      case HttpMethod.PUT:
        return this.httpClient.request(url, HttpMethod.PUT, callback, data, header);
      default:
        return Promise.reject({
          status: HTTP_STATUS_CODE.METHOD_NOT_ALLOWED
        });
    }
  }

  private retryRequest(
    url: string,
    method: string,
    header: any,
    data: any,
    success: any,
    fail: any
  ) {
    this.internalRequest(url, method, header, data, (err: any, response: any) => {
      if (err) {
        const errorMsg = JSON.stringify(err);
        Logger.warn(TAG, `[Http Adapter fail] =>${errorMsg}`);
        fail(errorMsg);
        return;
      }
      const responseCode = response.responseCode;
      if (responseCode >= HTTP_STATUS_CODE.OK && responseCode < HTTP_STATUS_CODE.MULTIPLE_CHOICES) {
        success({
          statusCode: responseCode,
          data: response.result
        });
      } else {
        Logger.warn(TAG, `[Http Adapter fail] =>${responseCode} ${response.result}`);
        fail({ status: responseCode, statusText: response.result });
      }
    }).catch((error: any) => {
      fail(error);
    });
  }
}
