/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

export class CloudDBCryptoJS {
  private static CryptoJS: any;

  public static setCryptoJS(cryptoJS: any): void {
    this.CryptoJS = cryptoJS;
  }

  public static getCryptoJS(): any {
    return this.CryptoJS;
  }
}
