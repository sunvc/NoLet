/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
// @ts-ignore
import Long from 'long';
import { CommunicateTask } from '../communicator/CommunicateTask';
import { CommunicateTaskQueue } from '../communicator/CommunicateTaskQueue';
import { WebSocketClient } from '../communicator/websocket/WebSocketClient';
import { CertificateService } from '../security/CertificateService';
import { ContextWrapper } from '../utils/ContextWrapper';
import { SyncMessageType } from './utils/EntityTemplate';
import { Utils } from '../utils/Utils';
import { SyncResult } from './request/SyncResult';
import { naturalcloudsyncv2 } from '../generated/syncmessage';
import { ErrorCode } from '../utils/ErrorCode';
import { SyncTask } from './task/SyncTask';

import SyncResponseMessage = naturalcloudsyncv2.SyncResponseMessage;

const PUSH_MESSAGE_TASK_ID = -1;
const TAG = 'SyncRequestProcessor';

export class SyncRequestProcessor {
  private static taskId = Long.fromNumber(1); // taskId starts from 1, 0 for push message
  private static traceId?: string;

  private webSocketResponse = new Map();
  private taskMap = new Map();
  private communicateTaskQueue = new CommunicateTaskQueue();
  private subscribeTaskIdSet: Set<string> = new Set();
  private subscribeRecordSet: Set<string> = new Set();
  private encryptionInfoPush?: (ExceptionCode: ErrorCode, syncResult: SyncResult) => any;
  private certificateService: CertificateService;
  private webSocketClient: WebSocketClient;

  static generateTaskId(): Long {
    this.taskId = this.taskId.add(1);
    return this.taskId;
  }

  static setTraceId(traceId?: string): any {
    this.traceId = traceId;
  }

  static generalTraceId(): string {
    return this.traceId ? this.traceId : Utils.generateTraceId();
  }

  constructor(certificateService: CertificateService) {
    this.certificateService = certificateService;
    this.webSocketClient = new WebSocketClient(certificateService);
    this.webSocketClient.registerResponseCallback((isSuccess: boolean, message: any) => {
      this.onWebSocketResponse(isSuccess, message);
    });
  }

  public registerConnectCallback(connectCallback: any): void {
    this.webSocketClient.registerConnectCallback(() => {
      if (this.hasSubscriber()) {
        Logger.info(TAG, `do clear subscribes onConnect.`);
        this.clearSubscriber();
      }
      connectCallback.call(null);
    });
  }

  public registerDisconnectCallback(disconnectCallback: any): void {
    this.webSocketClient.registerDisconnectCallback((isInitiativeStop: boolean) => {
      if (this.needToConnectWebSocket() && !this.webSocketClient.isReconnectingState()) {
        Logger.info(
          TAG,
          'do reconnect when there is Subscriber or encryptionMonitor onDisconnect.'
        );
        this.webSocketClient.reconnect();
      }
      disconnectCallback.call(null, isInitiativeStop);
    });
  }

  public registerWebSocketCallBack(syncMessageType: SyncMessageType, task: any): void {
    // used for register websocket OnResponse
    // due to onResponse function and request function Coupling and OnResponse function is unchanging so use task
    if (task.syncRequest && task.syncRequest!.taskId) {
      this.taskMap.set(task.syncRequest?.taskId?.toString() || PUSH_MESSAGE_TASK_ID, task);
    } else {
      this.webSocketResponse.set(syncMessageType, task);
    }
  }

  public process(syncTask: SyncTask): void {
    if (this.verifyRequest() !== ErrorCode.OK) {
      Logger.warn(TAG, 'invalid request!');
      syncTask.handle(ErrorCode.INTERNAL_ERROR, new SyncResult());
      return;
    }
    this.communicateTaskQueue.enqueueTask(new CommunicateTask(syncTask, 0, syncTask.handle));
  }

  private verifyRequest(): ErrorCode {
    const context = this.certificateService.getContext();
    if (Utils.isEmpty(context)) {
      return ErrorCode.INVALID_APP_CONTEXT;
    }
    if (!context.productId) {
      return ErrorCode.INVALID_APP_CONTEXT;
    }
    return ErrorCode.OK;
  }

  public onWebSocketResponse(isSuccess: boolean, message: any): void {
    if (!isSuccess) {
      Logger.error(TAG, 'onWebSocketResponse: fail!');
      return;
    }
    const data = SyncResponseMessage.fromObject(message);
    const dataType = ContextWrapper.getWSocketMessageType(data);
    const syncResult: any = {
      responseCode: data.resInfo?.resCode || ErrorCode.OK,
      responseType: data.msgInfo?.type,
      taskId: data.msgInfo?.id,
      storeName: data.msgInfo?.opStore?.storeName
    };
    const taskId =
      Utils.isNullOrUndefined(syncResult.taskId) || syncResult.taskId <= 0
        ? PUSH_MESSAGE_TASK_ID
        : syncResult.taskId;
    Logger.info(
      TAG,
      `onWebSocketResponse taskId: ${taskId} responseType: ${syncResult.responseType}\
            dataType:${dataType}`
    );
    let response;
    if (taskId === PUSH_MESSAGE_TASK_ID) {
      response = [...this.webSocketResponse].filter(([key, value]) => key === dataType);
    } else {
      response = [...this.taskMap].filter(([key, value]) => key === taskId.toString());
    }
    response.forEach(([key, value]) => {
      value.onResponse(data, syncResult as SyncResult, this);
    });
    if (taskId !== PUSH_MESSAGE_TASK_ID) {
      this.taskMap.delete(taskId.toString());
    }
  }

  public getSubscribeTaskIdSet(): Set<string> {
    return this.subscribeTaskIdSet;
  }

  public getSubscribeRecordSet(): Set<string> {
    return this.subscribeRecordSet;
  }

  public clearSubscriber(): void {
    this.subscribeRecordSet.clear();
    this.subscribeTaskIdSet.clear();
  }

  public hasSubscriber(): boolean {
    return this.subscribeRecordSet.size !== 0 || this.subscribeTaskIdSet.size !== 0;
  }

  // It needs to disconnect websocket when there is no subscribe or no userKeyMonitor or userKey is expired
  public needToDisconnectWebsocket(): boolean {
    return !this.hasSubscriber() && !this.encryptionInfoPush;
  }

  // It needs to connect websocket when there is subscriber or userKeyMonitor and userKey is valid
  public needToConnectWebSocket(): boolean {
    return this.hasSubscriber() || !!this.encryptionInfoPush;
  }

  public async disConnectWebSocket(): Promise<void> {
    await this.webSocketClient.stop();
  }

  public tryToDisconnectWebsocket(): void {
    this.encryptionInfoPush = undefined;
    if (!this.hasSubscriber()) {
      this.webSocketClient.stop();
      Logger.info(TAG, `[tryToDisconnectWebsocket] since has no subscriber!`);
    } else {
      Logger.info(
        TAG,
        `[tryToDisconnectWebsocket] won't disconnect websocket since there's subscriber!`
      );
    }
  }

  public addEncryptStatusMonitor(
    encryptionStatusMonitor: (ExceptionCode: ErrorCode, syncResult: SyncResult) => any
  ) {
    this.encryptionInfoPush = encryptionStatusMonitor;
  }

  public getEncryptionInfoPush():
    | ((ExceptionCode: ErrorCode, syncResult: SyncResult) => any)
    | undefined {
    return this.encryptionInfoPush;
  }

  public getWebSocketClient(): WebSocketClient {
    return this.webSocketClient;
  }
}
