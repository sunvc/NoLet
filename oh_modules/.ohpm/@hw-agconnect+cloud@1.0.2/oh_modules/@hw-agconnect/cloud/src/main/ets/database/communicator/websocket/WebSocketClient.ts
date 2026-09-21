/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger, getRegion } from '@hw-agconnect/hmcore';
import { OHWebSocketAdapter } from './adapter/OHWebSocketAdapter';
import { CertificateService } from '../../security/CertificateService';
import { MessageType, ProtoHelper, SerializeType } from '../../sync/ProtoHelper';
import { AgcMsgType } from '../../sync/utils/EntityTemplate';
import { Utils } from '../../utils/Utils';
import { HttpMethod } from '../https/HttpsClient';
import { WebSocketAdapter } from './adapter/WebSocketAdapter';
import { State } from '../../struct/Monitor';
import { SyncRequest } from '../../sync/request/SyncRequest';

const DEFAULT_BACKOFF_INITIAL_DELAY_MS = 1000;
const DEFAULT_BACKOFF_FACTOR = 1.5;
const DEFAULT_BACKOFF_MAX_DELAY_MS = 60 * 1000;
const WEBSOCKET_SUCCESS_RESPONSE_CODE = 200;
const AGCGW_PREFIX = '/agc/apigw/clouddb';
const SLB_PREFIX = '/clouddbservice/sync';
const WS_COMMON = `${AGCGW_PREFIX}${SLB_PREFIX}/message`;
const WS_CLIENT_ONLINE = `${AGCGW_PREFIX}${SLB_PREFIX}/register`;
const WS_CLIENT_OFFLINE = `${AGCGW_PREFIX}${SLB_PREFIX}/unregister`;

const TAG = 'WebSocketClient';

let PUSH_MESSAGE_TIMES = 0;
let websocketKeepAliveInterval = 45000;

export enum ConnectionState {
  Disconnected,
  RequestToConnect,
  Connecting,
  Connected,
  Disconnecting
}

export class WebSocketClient {
  private readonly certificateService: CertificateService;
  private websocketAdapter!: WebSocketAdapter;
  private responseCallback?: any;
  private connectCallback?: any;
  private disconnectCallback?: any;
  private msgId = 0;
  private connectionState = ConnectionState.Disconnected;
  private isHeartBeatHasResp = 0;
  private isReconnecting = false;
  private isInitiativeStop = false;
  private keepaliveTimer: any = null;
  private currentBaseMs = 0;
  private lastAttemptTime = Date.now();
  private backoffFactor = DEFAULT_BACKOFF_FACTOR;
  private timerHandler: any = null;
  private deviceId = 0;
  private currentVersion = 0;
  private isEnableBackUrl = false;
  private subscribeDatas: Set<any> = new Set();
  private encryptRequest: Set<any> = new Set();
  private unsubscribeCallbacks: Map<string, any> = new Map();
  // nbCheck new websocket logic
  private isConnected = new State(false);

  public constructor(certificateService: CertificateService) {
    this.certificateService = certificateService;
  }

  public registerConnectCallback(connectCallback: any): void {
    if (connectCallback) {
      this.connectCallback = connectCallback;
    }
  }

  public registerDisconnectCallback(disconnectCallback: any): void {
    if (disconnectCallback) {
      this.disconnectCallback = disconnectCallback;
    }
  }

  private start(options: unknown, callback?: () => void): void {
    this.isInitiativeStop = false;
    if (!this.keepaliveTimer) {
      this.resetKeepAlive();
    }
    if (
      this.connectionState === ConnectionState.Connected ||
      this.connectionState === ConnectionState.Connecting
    ) {
      Logger.info(TAG, `websocket's already started, connectionState: ${this.connectionState}`);
      return;
    }
    Logger.info(TAG, 'start enter');
    this.connectionState = ConnectionState.Connecting;
    const listeners = this.getWebSocketListeners(callback);
    this.websocketAdapter = new OHWebSocketAdapter(listeners, getRegion());
    this.websocketAdapter.connect(options);
  }

  public async stop(): Promise<void> {
    if (
      this.connectionState === ConnectionState.Disconnecting ||
      this.connectionState === ConnectionState.Disconnected
    ) {
      return;
    }
    const websocketHeaders = await this.certificateService.getHeaderParam();
    const offLineMsg = {
      websocketMsgType: AgcMsgType.OFFLINE_MSG,
      websocketMsgId: this.msgId++,
      websocketMsgBody: {
        method: HttpMethod.POST,
        path: WS_CLIENT_OFFLINE,
        headers: websocketHeaders,
        body: ''
      }
    };
    if (this.connectionState === ConnectionState.Connected) {
      this.simplifiedSendMessage(JSON.stringify(offLineMsg));
    }
    this.connectionState = ConnectionState.Disconnecting;
    Logger.info(TAG, 'start to stop');
    this.websocketAdapter.close();
    this.clearKeepAliveTimer();
  }

  public registerResponseCallback(
    responseCallback?: (isSuccess: boolean, message: any) => void
  ): void {
    if (responseCallback) {
      this.responseCallback = responseCallback;
    }
  }

  private notifyResponseCallback(isSuccess: boolean, message: any): void {
    if (this.responseCallback) {
      this.responseCallback(isSuccess, message);
    }
  }

  public async sendSubscribeRequest(syncRequest: SyncRequest): Promise<void> {
    if (!Utils.isNotNullObject(syncRequest)) {
      Logger.error(TAG, 'sendSubscribeRequest: Invalid request, stop to send!');
      return;
    }
    Logger.info(TAG, `sendSubscribeRequest state:${this.connectionState}`);
    this.start(this.certificateService.getSubscribeOptions());
    if (this.connectionState !== ConnectionState.Connected) {
      Logger.info(TAG, `sendSubscribeRequest: network is not available, schedule to sendMessages!`);
      this.subscribeDatas.add(syncRequest);
      return;
    }
    const requests: Set<SyncRequest> = new Set();
    requests.add(syncRequest);
    Logger.info(TAG, `sendSubscribeRequest start sendMessages`);
    await this.sendMessages(requests);
  }

  public async sendUnsubscribeRequest(syncRequest: SyncRequest, callback: any): Promise<void> {
    if (!Utils.isNotNullObject(syncRequest)) {
      Logger.error(TAG, 'sendUnsubscribeRequest: Invalid request, stop to send!');
      return;
    }
    Logger.info(TAG, `sendUnsubscribeRequest state:${this.connectionState}`);
    if (
      this.connectionState === ConnectionState.Disconnecting ||
      this.connectionState === ConnectionState.Disconnected
    ) {
      Logger.info(
        TAG,
        `sendUnsubscribeRequest it is not connect state, skip to send unsubscribe request!`
      );
      callback.call(null);
      return;
    }
    if (this.connectionState === ConnectionState.Connected) {
      const requests: Set<SyncRequest> = new Set();
      requests.add(syncRequest);
      Logger.info(TAG, `sendUnsubscribeRequest start sendMessages`);
      this.unsubscribeCallbacks.set(syncRequest.taskId.toString(), callback);
      await this.sendMessages(requests);
    } else {
      Logger.info(
        TAG,
        `sendUnsubscribeRequest connectionState: ${this.connectionState}, skip to send request.`
      );
    }
  }

  private getWebSocketListeners(callback?: () => void): any {
    return ((client: WebSocketClient) => {
      return {
        _onopen: () => {
          this.onOpen(client, callback);
        },
        _onerror: (_: any) => {
          this.onError(client);
        },
        _onclose: (code: number, reason: string, wasClean: boolean) => {
          this.onClose(client, code, callback);
        },
        _onmessage: (data: any) => {
          this.onMessage(client, data);
        }
      };
    })(this);
  }

  private async onOpen(client: WebSocketClient, callback?: () => void): Promise<void> {
    const websocketHeaders = await this.certificateService.getHeaderParam();
    Logger.info(TAG, 'onOpen enter');
    client.connectionState = ConnectionState.Connected;
    client.currentVersion = client.currentVersion + 1;
    const msg = {
      websocketMsgType: AgcMsgType.ONLINE_MSG,
      websocketMsgId: this.msgId++,
      websocketMsgBody: {
        method: HttpMethod.POST,
        path: WS_CLIENT_ONLINE,
        params: { _v: SerializeType.JSON },
        headers: websocketHeaders,
        body: ''
      }
    };
    client.simplifiedSendMessage(JSON.stringify(msg));
    if (callback) {
      callback();
    }
  }

  /**
   * Subscribe encryption info,hold on websocket connection.
   * @param request monitor request data.
   * @param callback handler if success.
   */
  public async subEncryption(request: any, callback?: () => void): Promise<void> {
    Logger.info(TAG, `subEncryption enter: connectionState: ${this.connectionState}`);
    this.start(this.certificateService.getSubscribeOptions());
    if (this.connectionState !== ConnectionState.Connected) {
      this.encryptRequest.add(request);
      Logger.info(
        TAG,
        'subEncryption: websocket has not established yet, schedule to add encryption listener!'
      );
      return;
    }
    const requests: Set<any> = new Set();
    requests.add(request);
    await this.sendMessages(requests);
    if (callback) {
      callback();
    }
    Logger.debug(TAG, 'subEncryption: sendMessages done!');
  }

  private async sendMessages(request: Set<any>): Promise<void> {
    if (!request.size) {
      return;
    }
    const websocketHeaders = await this.certificateService.getHeaderParam();
    request.forEach(item => {
      item.deviceId = this.deviceId;
      const msg = {
        websocketMsgType: AgcMsgType.COMMON_MSG,
        websocketMsgId: this.msgId++,
        websocketMsgBody: {
          method: HttpMethod.POST,
          path: WS_COMMON,
          params: { _v: SerializeType.JSON },
          headers: websocketHeaders,
          body: JSON.stringify(ProtoHelper.serializeMessage(item, this.certificateService))
        }
      };
      request.delete(item);
      this.simplifiedSendMessage(JSON.stringify(msg));
    });
    request.clear();
  }

  private onError(client: WebSocketClient) {
    Logger.info(TAG, 'onError enter');
    client.resetConnectionState();
    if (this.disconnectCallback) {
      this.disconnectCallback(this.isInitiativeStop);
    }
    Logger.debug(TAG, 'onError done');
  }

  private async onClose(
    client: WebSocketClient,
    messageCode: any,
    callback?: () => void
  ): Promise<void> {
    /**
     * nbCheck onclose called means channel has been closed, however send message here
     */
    Logger.info(TAG, 'onClose enter');

    client.resetConnectionState();
    Logger.info(
      TAG,
      `onClose message.code: ${messageCode} isReconnecting: ${client.isReconnecting}`
    );
    if (callback) {
      callback();
    }
    if (this.disconnectCallback) {
      Logger.info(TAG, 'onClose disconnectCallback is called');
      this.disconnectCallback(this.isInitiativeStop);
    }
    Logger.info(TAG, 'onClose done');
    this.msgId = 0;
    Logger.info(TAG, 'Start release all unsubscribeCallbacks.');
    for (const value of this.unsubscribeCallbacks.values()) {
      value.call();
    }
    this.unsubscribeCallbacks.clear();
    Logger.info(TAG, 'Release all unsubscribeCallbacks success.');
  }

  private resetConnectionState(): void {
    this.clearKeepAliveTimer();
    this.connectionState = ConnectionState.Disconnected;
    this.isConnected.value = false;
  }

  public isReconnectingState(): boolean {
    return this.isReconnecting;
  }

  private sizeof(str: string): number {
    let total = 0;
    let charCode;
    let i;
    let len;
    for (i = 0, len = str.length; i < len; i++) {
      charCode = str.charCodeAt(i);
      if (charCode <= 0x007f) {
        total += 1;
      } else if (charCode <= 0x07ff) {
        total += 2;
      } else if (charCode <= 0xffff) {
        total += 3;
      } else {
        total += 4;
      }
    }
    return total;
  }

  private onMessage(client: WebSocketClient, data: any): void {
    Logger.info(TAG, 'onMessage enter');
    if (data) {
      let agcMessage;
      try {
        agcMessage = JSON.parse(data);
      } catch (e) {
        Logger.error(TAG, `onMessage: fail ,parse data failed, type =  ${typeof data}.`);
        return;
      }
      if (Object.prototype.hasOwnProperty.call(agcMessage, 'websocketMsgType')) {
        this.handleAGCMessage(agcMessage, client, this);
      } else {
        Logger.warn(TAG, `Unknown websocket message length = ${data?.length}`);
      }
    }
  }

  private handleAGCMessage(agcMessage: any, client: WebSocketClient, self: any): void {
    Logger.info(TAG, `receive agc push message msgId: ${agcMessage.websocketMsgId}`);
    const AGCMessageHandlerMap = this.getAGCMsgHandlerMap();
    const find = AGCMessageHandlerMap.find(
      handler => handler.agcMessageType === agcMessage.websocketMsgType
    );
    if (!find) {
      Logger.debug(
        TAG,
        `handleAGCMessage: useless agcMessage responseType: ${agcMessage?.websocketMsgType}`
      );
      return;
    }
    Logger.info(TAG, `handleAGCMessage websocketMsgType: ${agcMessage.websocketMsgType}`);
    find.handler(agcMessage, client, self);
  }

  private getAGCMsgHandlerMap(): any[] {
    return [
      {
        agcMessageType: AgcMsgType.ONLINE_RESP_MSG,
        handler: (agcMessage: any, client: WebSocketClient, self: any) => {
          const { channelId } = this.parseJson(agcMessage.websocketMsgBody.body) as any;
          if (!channelId) {
            return;
          }
          self.setDeviceId(channelId);
          self.resubscribeAll();
          if (self.connectCallback) {
            self.connectCallback();
          }
        }
      },
      {
        agcMessageType: AgcMsgType.HEARTBEAT_RSP,
        handler: (agcMessage: any, client: WebSocketClient, self: any) => {
          self.isHeartBeatHasResp = 0;
          const interval = Math.floor(agcMessage.websocketChannelIdleTimeout / 3) * 1000;
          if (websocketKeepAliveInterval !== interval) {
            websocketKeepAliveInterval = interval;
            self.resetKeepAlive();
          }
        }
      },
      {
        agcMessageType: AgcMsgType.SERVER_PUSH_MSG,
        handler: (agcMessage: any, client: WebSocketClient, self: any) => {
          self.simplifiedSendMessage(
            JSON.stringify({
              websocketMsgType: AgcMsgType.SERVER_PUSH_MSG_RSP,
              websocketMsgId: agcMessage.websocketMsgId,
              websocketMsgBody: {
                status: WEBSOCKET_SUCCESS_RESPONSE_CODE,
                body: 'ok'
              }
            })
          );
          const pushMsg = this.parseJson(agcMessage.websocketMsgBody.body) as any;
          const {
            msgInfo: { id, type }
          } = pushMsg;
          if (!type) {
            return;
          }
          this.unsubscribeCallbacks.delete(id);
          if (type === MessageType.QUERY_SUB || type === MessageType.QUERY_UNSUB) {
            Logger.debug(
              TAG,
              `TrafficStatistics:${PUSH_MESSAGE_TIMES++}.Receiver \
                        ${this.sizeof(agcMessage.websocketMsgBody.body)}B.`
            );
          }
          client.notifyResponseCallback(true, pushMsg);
        }
      }
    ];
  }

  private sendHeartBeatMessage(): void {
    const that = this;
    that.isHeartBeatHasResp++;
    if (this.connectionState !== ConnectionState.Connected) {
      return;
    }
    const heartBeatMsg = {
      websocketMsgType: AgcMsgType.HEARTBEAT_MSG,
      websocketMsgId: this.msgId++
    };
    setTimeout(() => {
      Logger.debug(TAG, 'start check heartBeat response.');
      if (that.isHeartBeatHasResp > 2) {
        Logger.warn(TAG, `heartBeat timeout, lost ${that.isHeartBeatHasResp} package.`);
        this.connectionState = ConnectionState.Disconnecting;
        this.websocketAdapter.close({ eventCode: 3001 });
      }
      Logger.debug(TAG, 'check heartBeat response finish.');
    }, 10000);
    this.simplifiedSendMessage(JSON.stringify(heartBeatMsg));
  }

  private resetKeepAlive(): void {
    this.clearKeepAliveTimer();
    Logger.debug(TAG, 'resetKeepAlive enter.');
    this.sendHeartBeatMessage();
    this.keepaliveTimer = setInterval(() => {
      this.sendHeartBeatMessage();
    }, Math.floor(websocketKeepAliveInterval));
  }

  private parseJson(message: any): object {
    let result: object = {};
    if (typeof message !== 'string') {
      Logger.warn(TAG, `parse json type error for${typeof message}`);
      return result;
    }
    try {
      result = JSON.parse(message);
    } catch (e) {
      Logger.warn(TAG, `Parse json error for${e},message length =${message?.length}`);
    }
    return result;
  }

  private needReconnect(): boolean {
    return this.connectionState !== ConnectionState.Connected && !this.isInitiativeStop;
  }

  public reconnect(): void {
    const desiredDelayWithJitterMs = Math.floor(this.currentBaseMs * DEFAULT_BACKOFF_FACTOR);
    const delaySoFarMs = Math.max(0, Date.now() - this.lastAttemptTime);
    const remainingDelayMs = Math.max(0, desiredDelayWithJitterMs - delaySoFarMs);
    this.lastAttemptTime = Date.now();
    Logger.info(
      TAG,
      `reconnect enter: remainingDelayMs: ${remainingDelayMs} connState: ${this.connectionState}`
    );
    const options = this.isEnableBackUrl
      ? this.certificateService.getSubscribeBackOptions()
      : this.certificateService.getSubscribeOptions();
    this.isEnableBackUrl = !this.isEnableBackUrl;
    this.timerHandler = setTimeout(() => {
      this.start(options, () => {
        if (this.needReconnect()) {
          clearTimeout(this.timerHandler);
          this.isReconnecting = true;
          this.reconnect();
        } else {
          this.currentBaseMs = 0;
          this.isReconnecting = false;
        }
      });
    }, remainingDelayMs);
    this.currentBaseMs *= this.backoffFactor;
    if (this.currentBaseMs < DEFAULT_BACKOFF_INITIAL_DELAY_MS) {
      this.currentBaseMs = DEFAULT_BACKOFF_INITIAL_DELAY_MS;
    }
    if (this.currentBaseMs > DEFAULT_BACKOFF_MAX_DELAY_MS) {
      this.currentBaseMs = DEFAULT_BACKOFF_MAX_DELAY_MS;
    }
  }

  private clearKeepAliveTimer(): void {
    if (this.keepaliveTimer) {
      clearInterval(this.keepaliveTimer);
      this.keepaliveTimer = null;
    }
  }

  public stopHeartBeat(): void {
    this.isInitiativeStop = true;
    this.clearKeepAliveTimer();
  }

  private async resubscribeAll(): Promise<void> {
    Logger.info(
      TAG,
      `schedule to resubscribeAll: ${this.encryptRequest.size} ${this.subscribeDatas.size}`
    );
    await this.sendMessages(this.encryptRequest);
    await this.sendMessages(this.subscribeDatas);
  }

  private simplifiedSendMessage(
    data: any,
    success?: (msg: any) => void,
    fail?: (error: any) => void
  ): void {
    const param = {
      data,
      success: success ? success : () => {},
      fail: fail ? fail : () => {}
    };
    Logger.info(TAG, 'simplifiedSendMessage sendMessage');
    this.websocketAdapter.sendMessage(param);
  }

  private setDeviceId(deviceId: number): void {
    this.deviceId = deviceId;
    this.currentVersion++;
  }
}
