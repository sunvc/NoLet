/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2022. All rights reserved.
 */

import { WebSocketAdapter } from './WebSocketAdapter';
import webSocket from '@ohos.net.webSocket';
import { ExceptionUtil } from '../../../utils/ExceptionUtil';
import { ErrorCode } from '../../../utils/ErrorCode';

const WEBSOCKET_MAP = new Map<string, any>();

export class OHWebSocketAdapter implements WebSocketAdapter {
  private readonly ohWebsocket: any;
  private readonly region: string;
  private readonly listeners: any;

  constructor(listeners: any, region: string) {
    this.listeners = listeners;
    this.region = region;
    if (WEBSOCKET_MAP.has(region)) {
      this.ohWebsocket = WEBSOCKET_MAP.get(region);
    } else {
      this.ohWebsocket = webSocket.createWebSocket();
      WEBSOCKET_MAP.set(region, this.ohWebsocket);
    }
  }

  close(object?: any): void {
    WEBSOCKET_MAP.delete(this.region);
  }

  connect(object: any): void {
    if (!object) {
      throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
    }

    this.ohWebsocket.connect(object.url, { header: object.header });

    this.ohWebsocket.on('open', (err: any, value: any) => {
      this.listeners._onopen();
    });

    this.ohWebsocket.on('message', (err: any, value: any) => {
      this.listeners._onmessage(value);
    });

    this.ohWebsocket.on('close', (err: any, value: any) => {
      this.listeners._onclose(value.code, value.reason, true);
    });

    this.ohWebsocket.on('error', (err: any) => {
      this.listeners._onerror(err);
    });
  }

  sendMessage(object: any): void {
    this.ohWebsocket?.send(object.data);
  }
}
