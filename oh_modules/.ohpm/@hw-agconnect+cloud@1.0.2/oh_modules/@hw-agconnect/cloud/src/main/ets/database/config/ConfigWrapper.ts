import { OHConfigAdapter } from './OHConfigAdapter';
/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */
import { Config } from './Config';

export class ConfigWrapper {
  private static configInstance: Config;

  public static getConfigInstance(): Config {
    if (!this.configInstance) {
      this.configInstance = new OHConfigAdapter();
    }
    return this.configInstance;
  }
}
