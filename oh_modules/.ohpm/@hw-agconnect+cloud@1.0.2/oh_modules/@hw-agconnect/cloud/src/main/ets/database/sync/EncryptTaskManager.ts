/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
// @ts-ignore
import Long from 'long';
import { CallbackTask } from './utils/CallbackTask';
import { EncryptRequest } from './request/EncryptRequest';
import { SyncRequestProcessor } from './SyncRequestProcessor';
import { EncryptionResponse, SyncResult } from './request/SyncResult';
import { EncryptionStatusMonitor } from './EncryptionStatusMonitor';
import { EncryptInfo, EncryptionKeyStatus, EncryptResult } from './utils/EncryptInfo';
import { ErrorCode } from '../utils/ErrorCode';
import { MessageSubType } from './utils/MessageType';
import { MonitorTask } from './task/MonitorTask';
import { HttpRequestTask } from './task/HttpRequestTask';
import { NaturalBaseRef } from '../base/NaturalBaseRef';
import { SyncMessageType } from './utils/EntityTemplate';

const TAG = 'EncryptTaskManager';

export class EncryptTaskManager {
  private static ENCRYPT_TASK_TIMEOUT_IN_MILLISECOND = 60000;
  private encryptTaskCacheMap: Map<string, EncryptTask> = new Map<string, EncryptTask>();
  private syncProcess: SyncRequestProcessor;
  private readonly naturalBaseRef: NaturalBaseRef;

  constructor(syncProcess: SyncRequestProcessor, naturalBaseRef: NaturalBaseRef) {
    this.syncProcess = syncProcess;
    this.naturalBaseRef = naturalBaseRef;
    this.naturalBaseRef.getEntireEncryptInterval().saveEncryptTaskManager(this);
  }

  clearEncryptInfo(encryptInfoArray: EncryptInfo[]): void {
    encryptInfoArray.forEach((encryptInfo: EncryptInfo) => {
      encryptInfo.clear();
    });
    encryptInfoArray.length = 0;
  }

  public async addEncryptionListener(
    encryptionStatusMonitor: EncryptionStatusMonitor
  ): Promise<void> {
    let result = await this.processEncryptionTask(MessageSubType.MONITOR_USER_COMMAND_CHANGE, []);
    if (result.resultCode !== ErrorCode.OK) {
      Logger.error(
        TAG,
        `addEncryptionListener: add user command monitor fail: ${result.resultCode}`
      );
      return;
    }
    result = await this.processEncryptionTask(MessageSubType.MONITOR_DATA_KEY_CHANGE, []);
    if (result.resultCode !== ErrorCode.OK) {
      Logger.error(TAG, `addEncryptionListener: add data key monitor fail: ${result.resultCode}`);
      return;
    }
    this.syncProcess.addEncryptStatusMonitor((errorCode: ErrorCode, syncResult: SyncResult) => {
      if (errorCode === ErrorCode.OK) {
        Logger.info(TAG, `addEncryptionListener: receive notification success.`);
        this.handleEncryptPushMessage(syncResult, encryptionStatusMonitor);
      } else {
        Logger.warn(TAG, `addEncryptionListener: get notification fail for ${errorCode}.`);
      }
    });
    Logger.info(TAG, `addEncryptionListener: add user encryption changed monitor success!`);
  }

  public tryToDisconnectWhenClearUserKey(): void {
    this.syncProcess.tryToDisconnectWebsocket();
  }

  private async processEncryptionTask(
    requestSubType: MessageSubType,
    requestEncryptInfos: EncryptInfo[]
  ): Promise<EncryptResult> {
    const taskId = SyncRequestProcessor.generateTaskId();
    const encryptTask = new EncryptTask(requestSubType, taskId, requestEncryptInfos);
    this.encryptTaskCacheMap.set(taskId.toString(), encryptTask);
    Logger.info(TAG, `processEncryptionTask: taskId: ${taskId} encryptType: ${requestSubType}`);
    const result = await encryptTask.executeWithTimeout(
      EncryptTaskManager.ENCRYPT_TASK_TIMEOUT_IN_MILLISECOND,
      async (): Promise<EncryptResult> => {
        const request = new EncryptRequest(
          encryptTask.requestSubType,
          encryptTask.requestInfo,
          encryptTask.taskId
        );
        return await this.onEncryptTask(request);
      }
    );
    Logger.info(TAG, `processEncryptionTask resultCode:${result.resultCode}`);
    return result;
  }

  private async onEncryptTask(request: EncryptRequest): Promise<EncryptResult> {
    return await new Promise<EncryptResult>((resolve, reject) => {
      let task;
      const handle = (errorCode: ErrorCode, syncResult: SyncResult) => {
        Logger.debug(TAG, `onWebsocketTask: handle encrypt resultCode: ${errorCode}`);
        if (errorCode !== ErrorCode.OK) {
          Logger.error(TAG, 'onWebsocketTask: fail to send encrypt task!');
          reject(new EncryptResult(errorCode, []));
          return;
        }
        resolve(this.handleEncryptTaskResult(syncResult));
      };
      if (
        request.requestSubType === MessageSubType.MONITOR_USER_COMMAND_CHANGE ||
        request.requestSubType === MessageSubType.MONITOR_DATA_KEY_CHANGE
      ) {
        task = new MonitorTask(
          request,
          this.naturalBaseRef.getEntireEncryption().GetEncryptVersion(),
          handle,
          this.syncProcess
        );
        this.syncProcess.registerWebSocketCallBack(SyncMessageType.EncryptionResponse, task);
      } else {
        task = new HttpRequestTask(
          request,
          this.naturalBaseRef.getEntireEncryption().GetEncryptVersion(),
          this.naturalBaseRef.getCertificateService(),
          handle
        );
      }
      this.syncProcess.process(task);
    });
  }

  public async querySaltValue(): Promise<EncryptResult> {
    Logger.debug(TAG, `querySaltValue start`);
    return this.processEncryptionTask(MessageSubType.QUERY_SALT_VALUE, []);
  }

  public async queryDataKeyCipherText(requestInfo: EncryptInfo): Promise<EncryptResult> {
    Logger.info(TAG, `queryDataKeyCipherText start`);
    if (requestInfo.rootKeyToken?.length === 0) {
      Logger.error(TAG, 'queryDataKeyCipherText fail: requestInfo rootKeyToken is empty!');
      return Promise.reject(ErrorCode.VERIFY_TOKEN_FAILED);
    }
    return this.processEncryptionTask(MessageSubType.QUERY_CIPHER_TEST, [requestInfo]);
  }

  public async insertEncryptedInfo(insertEncryptInfo: EncryptInfo): Promise<EncryptResult> {
    Logger.info(TAG, `insertEncryptedInfo start`);
    if (
      insertEncryptInfo.firstSaltValue?.length === 0 ||
      insertEncryptInfo.secondSaltValue?.length === 0 ||
      insertEncryptInfo.rootKeyToken?.length === 0 ||
      insertEncryptInfo.dataKeyCipherText?.length === 0
    ) {
      Logger.error(TAG, 'insertEncryptedInfo fail: insert encrypt info contains empty buffer!');
      return Promise.reject(ErrorCode.VERIFY_TOKEN_FAILED);
    }
    return this.processEncryptionTask(MessageSubType.INSERT_ENCRYPTION_INFO, [insertEncryptInfo]);
  }

  public async updateEncryptedInfo(
    oldEncryptInfo: EncryptInfo,
    newEncryptInfo: EncryptInfo
  ): Promise<EncryptResult> {
    Logger.info(TAG, `updateEncryptedInfo start`);
    if (oldEncryptInfo.rootKeyToken?.length === 0) {
      Logger.error(TAG, 'updateEncryptedInfo: old encrypt rootKeyToken is null!');
      return Promise.reject(ErrorCode.VERIFY_TOKEN_FAILED);
    }
    if (
      newEncryptInfo.firstSaltValue?.length === 0 ||
      newEncryptInfo.secondSaltValue?.length === 0 ||
      newEncryptInfo.rootKeyToken?.length === 0 ||
      newEncryptInfo.dataKeyCipherText?.length === 0
    ) {
      Logger.error(TAG, 'updateEncryptedInfo: new encrypt contains empty buffer!');
      return Promise.reject(ErrorCode.VERIFY_TOKEN_FAILED);
    }
    return this.processEncryptionTask(MessageSubType.UPDATE_ENCRYPTION_INFO, [
      oldEncryptInfo,
      newEncryptInfo
    ]);
  }

  private handleEncryptTaskResult(result: SyncResult): EncryptResult {
    const resultCode = result.responseCode;
    if (resultCode !== ErrorCode.OK) {
      Logger.warn(TAG, `handleEncryptTaskResult: cloud encryption exception occurs!`);
      return new EncryptResult(resultCode, []);
    }
    const encryptTask = this.encryptTaskCacheMap.get(result.taskId.toString());
    if (!encryptTask) {
      Logger.error(TAG, `handleEncryptTaskResult: invalid encryptTask, taskId: ${result.taskId}`);
      return new EncryptResult(ErrorCode.SYNC_TASK_NO_RESPONSE, []);
    }
    const encryptionResponse = result.response as EncryptionResponse;
    Logger.info(
      TAG,
      `handleEncryptTaskResult: taskId: ${result.taskId} \
            encryptType: ${encryptionResponse.encryptionMessageType} \
            responseInfo size:${encryptionResponse.encryptionInfoList?.length}`
    );
    if (encryptTask.requestSubType !== encryptionResponse.encryptionMessageType) {
      Logger.error(
        TAG,
        'handleEncryptTaskResult: response encrypt type does not matched with task encrypt type'
      );
      this.clearEncryptInfo(encryptTask.requestInfo);
      this.encryptTaskCacheMap.delete(result.taskId.toString());
      return new EncryptResult(ErrorCode.SYNC_TASK_NO_RESPONSE, []);
    }
    const responseInfo: EncryptInfo[] = [];
    encryptionResponse.encryptionInfoList?.forEach(info => {
      responseInfo.push(info);
    });
    this.clearEncryptInfo(encryptTask.requestInfo);
    this.encryptTaskCacheMap.delete(result.taskId.toString());
    Logger.debug(
      TAG,
      `handleEncryptTaskResult: encryptTaskCacheMap size: ${this.encryptTaskCacheMap.size}`
    );
    return new EncryptResult(ErrorCode.OK, responseInfo);
  }

  private handleEncryptPushMessage(
    result: SyncResult,
    encryptionStatusMonitor: EncryptionStatusMonitor
  ): ErrorCode {
    if (!encryptionStatusMonitor) {
      Logger.error(TAG, `handleEncryptPushMessage: no encryption monitor registered!`);
      return ErrorCode.OK;
    }
    const onUserCommandChanged = (monitor: EncryptionStatusMonitor) => {
      monitor.onUserCommandChanged();
    };
    const onKeyStatusNormal = (monitor: EncryptionStatusMonitor) => {
      monitor.onKeyChanged(EncryptionKeyStatus.NORMAL);
    };
    const onKeyStatusUpdating = (monitor: EncryptionStatusMonitor) => {
      monitor.onKeyChanged(EncryptionKeyStatus.UPDATING);
    };
    const onKeyStatusInterrupt = (monitor: EncryptionStatusMonitor) => {
      monitor.onKeyChanged(EncryptionKeyStatus.INTERRUPT);
    };
    const notificationMap = new Map([
      [MessageSubType.NOTIFY_ENCRYPTION_COMMAND_CHANGED, onUserCommandChanged],
      [MessageSubType.NOTIFY_ENCRYPTION_KEY_CHANGE_TO_NORMAL, onKeyStatusNormal],
      [MessageSubType.NOTIFY_ENCRYPTION_KEY_CHANGE_TO_UPDATING, onKeyStatusUpdating],
      [MessageSubType.NOTIFY_ENCRYPTION_KEY_CHANGE_TO_UPDATE_INTERRUPT, onKeyStatusInterrupt]
    ]);
    const encryptionMessageType = (result.response as EncryptionResponse).encryptionMessageType;
    Logger.info(TAG, `handleEncryptPushMessage: notificationType: ${encryptionMessageType}`);
    if (notificationMap.has(encryptionMessageType)) {
      notificationMap.get(encryptionMessageType)?.call(null, encryptionStatusMonitor);
      return ErrorCode.OK;
    } else {
      Logger.error(TAG, `handleEncryptPushMessage: invalid encryption push type!`);
      return ErrorCode.SYNC_TASK_NO_RESPONSE;
    }
  }
}

export class EncryptTask extends CallbackTask {
  private requestSubType_: MessageSubType;

  private taskId_: Long = Long.fromNumber(0);

  private resultCode_: number = ErrorCode.OK;

  private requestInfo_: EncryptInfo[] = [];

  constructor(requestSubType: MessageSubType, taskId: Long, requestInfo: EncryptInfo[]) {
    super();
    this.taskId_ = taskId;
    this.requestSubType_ = requestSubType;
    requestInfo.forEach((request: EncryptInfo) => {
      this.requestInfo_.push(request);
    });
  }

  get requestSubType(): number {
    return this.requestSubType_;
  }

  set requestSubType(requestSubType: number) {
    this.requestSubType_ = requestSubType;
  }

  get taskId(): Long {
    return this.taskId_;
  }

  get resultCode(): number {
    return this.resultCode_;
  }

  set resultCode(code: number) {
    this.resultCode_ = code;
  }

  get requestInfo(): EncryptInfo[] {
    return this.requestInfo_;
  }

  clearRequestInfo(): void {
    this.requestInfo_ = [];
  }
}
