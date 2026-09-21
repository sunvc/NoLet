/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import http from '@ohos.net.http';

const TAG = 'OHHttpsClient';

export class OHHttpsClient {
  private readonly defaultTimeout = 60000;

  public constructor() {}

  public async request(
    url: string,
    method: string,
    callback: (err: any, result: any) => void,
    param?: any,
    header?: any
  ): Promise<void> {
    const isArrayBuffer: boolean = param instanceof ArrayBuffer;
    const data = isArrayBuffer ? param : JSON.stringify(param);
    const httpRequest = http.createHttp();
    httpRequest.request(
      url,
      {
        method: method as http.RequestMethod,
        header: header,
        extraData: data,
        connectTimeout: this.defaultTimeout,
        readTimeout: this.defaultTimeout
      },
      (err: any, resultData: any) => {
        if (!err) {
          Logger.debug(TAG, 'resultData = ' + typeof resultData);
          Logger.debug(TAG, 'resultData.result = ' + typeof resultData?.result);
          Logger.info(TAG, 'OHHttpsClient request process success!');
          callback(err, resultData);
        } else {
          Logger.error(TAG, `OHHttpsClient request process failed.`);
          callback(err, resultData);
          httpRequest.destroy();
        }
      }
    );
  }
}
