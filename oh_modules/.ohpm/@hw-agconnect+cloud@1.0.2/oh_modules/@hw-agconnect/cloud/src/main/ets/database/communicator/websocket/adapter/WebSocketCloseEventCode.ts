/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

export const enum WEBSOCKET_CLOSEEVENT_CODE {
  'CLOSE_NORMAL' = 1000,
  'CLOSE_GOING_AWAY' = 1001,
  'CLOSE_PROTOCOL_ERROR' = 1002,
  'CLOSE_UNSUPPORTED' = 1003,
  'CLOSE_NO_STATUS' = 1005,
  'CLOSE_ABNORMAL' = 1006,
  'Unsupported Data' = 1007,
  'Policy Violation' = 1008,
  'CLOSE_TOO_LARGE' = 1009,
  'Missing Extension' = 1010,
  'Internal Error' = 1011,
  'Service Restart' = 1012,
  'Try Again Later' = 1013,
  'TLS Handshake' = 1015
}
