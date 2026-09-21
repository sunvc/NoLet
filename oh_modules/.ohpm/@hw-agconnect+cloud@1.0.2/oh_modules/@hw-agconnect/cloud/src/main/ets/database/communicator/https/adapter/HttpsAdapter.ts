/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

/**
 * HttpsAdapter class
 */
export abstract class HttpsAdapter {
  public request(object: unknown): void {
    const data = object;
    this.realRequest(data);
  }

  protected abstract realRequest(object: any): void;
}

export const enum HTTP_STATUS_CODE {
  OK = 200,
  MULTIPLE_CHOICES = 300,
  METHOD_NOT_ALLOWED = 405
}
