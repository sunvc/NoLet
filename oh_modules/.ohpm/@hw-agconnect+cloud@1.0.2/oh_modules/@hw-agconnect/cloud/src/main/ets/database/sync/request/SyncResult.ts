/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { EncryptInfo } from '../utils/EncryptInfo';
// @ts-ignore
import Long from 'long';
import { ErrorCode } from '../../utils/ErrorCode';
import { MessageSubType, MessageType, ServerPushOperationType } from '../utils/MessageType';

export class ObjectSyncResponse {
  data!: {
    tableName: string;
    data: any[];
  }[];
}

export class CloudObjectSyncResponse {
  queryId!: string;
  successNumber!: number;
}

export enum QueryType {
  CONVENTIONAL_QUERY = 0,
  AVG_QUERY
}

export class AggreResult {
  isNull?: boolean | null;
  longRes?: Long | null;
  doubleRes?: number | null;
}

export class QueryResponse {
  tableName!: string;
  queryResult!: boolean;
  queryType!: QueryType;
  totalLength!: number;
  aggreResult!: AggreResult;
  responseObject!: any[];
}

export class TransactionResponse {
  transactionId!: string;
  transactionResult!: ErrorCode;
}

export class QuerySubscribeResponse {
  subscribeResults!: {
    cloudSubRecordId: string;
    subscribeId: string;
    subKey: number;
    subResponseCode?: ErrorCode | null;
  }[];
}

export class QueryUnSubscribeResponse {
  unSubScribeResults!: {
    unSubRecId: string;
    unSubResCode: number;
  }[];
}

export class QuerySubscribePushResponse {
  subRecId!: string;
  responseObject!: any[];
  pushSeq!: number;
  subKey!: number;
  storeName!: string;
  subscribeId!: string;
  tableName?: string;
  operationType?: ServerPushOperationType;
}

export class EncryptionResponse {
  encryptionMessageType!: MessageSubType;
  encryptionInfoList: EncryptInfo[] = [];
}

export class SyncResult {
  responseCode!: number;
  type!: MessageType;
  subType!: MessageSubType;
  taskId!: Long;
  storeName!: string;
  response!:
    | ObjectSyncResponse
    | CloudObjectSyncResponse
    | QueryResponse
    | TransactionResponse
    | QuerySubscribeResponse
    | QueryUnSubscribeResponse
    | QuerySubscribePushResponse
    | EncryptionResponse
    | undefined;
}
