/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

/**
 * AGConnectCloudDB exception basic class.
 *
 * @since 2020-09-15
 */
export class DatabaseException {
  readonly message: string;
  readonly code: number;

  /**
   * Constructs a new DatabaseException with msg as its detail message.
   *
   * @param message detail message.
   * @param code the error code of exception.
   */
  public constructor(message: string, code: number) {
    this.message = message;
    this.code = code;
  }

  public getCode(): number {
    return this.code;
  }

  public getMessage(): string {
    return this.message;
  }
}
