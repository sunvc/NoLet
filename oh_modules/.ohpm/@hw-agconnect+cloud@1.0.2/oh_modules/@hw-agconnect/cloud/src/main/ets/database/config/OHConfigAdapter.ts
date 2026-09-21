/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 */

import { Config } from './Config';
import hmcloud from '../../hmcloud';

export class OHConfigAdapter implements Config {
  async getCurrentUser(): Promise<any> {
    return hmcloud.auth().getCurrentUser();
  }
}
