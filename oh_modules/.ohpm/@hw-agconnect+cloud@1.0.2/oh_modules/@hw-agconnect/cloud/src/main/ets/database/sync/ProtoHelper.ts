/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { IConversionOptions } from 'protobufjs';
import { NaturalStoreObjectSchema } from '../base/NaturalStoreObjectSchema';
import { CertificateService } from '../security/CertificateService';
import { DataTypeMap, ObjectWrapper } from './ObjectWrapper';
import {
  CloudObjectSyncResponse,
  EncryptionResponse,
  QueryResponse,
  QuerySubscribePushResponse,
  QuerySubscribeResponse,
  QueryType,
  QueryUnSubscribeResponse,
  SyncResult,
  TransactionResponse
} from './request/SyncResult';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { ErrorCode } from '../utils/ErrorCode';
import { naturalcloudsyncv2 } from '../generated/syncmessage';
import { SyncRequest } from './request/SyncRequest';
import { MessageSubType, MessageType, OperationType } from './utils/MessageType';
import { EncryptInfo } from './utils/EncryptInfo';
import { FieldInfo } from '../query/FieldInfo';
import { SyncObjectRequest } from './request/SyncObjectRequest';
import { SyncQueryRequest } from './request/SyncQueryRequest';
import { TransactionData, TransactionRequest } from './request/TransactionRequest';
import { SubscribeRequest } from './request/SubscribeRequest';
import { UnSubscribeRequest } from './request/UnsubscribeRequest';
import { EncryptRequest } from './request/EncryptRequest';

import ClientInfo = naturalcloudsyncv2.ClientInfo;
import EncryptionInfo = naturalcloudsyncv2.EncryptionInfo;
import SyncResponseMessage = naturalcloudsyncv2.SyncResponseMessage;
import SyncRequestMessage = naturalcloudsyncv2.SyncRequestMessage;
import MessageInfo = naturalcloudsyncv2.MessageInfo;
import Store = naturalcloudsyncv2.Store;
import OperationData = naturalcloudsyncv2.OperationData;
import SubscribeResponseMessage = naturalcloudsyncv2.SubscribeResponseMessage;
import SubscribePushMessage = naturalcloudsyncv2.SubscribePushMessage;
import Schema = naturalcloudsyncv2.Schema;
import UnsubscribeResponseMessage = naturalcloudsyncv2.UnsubscribeResponseMessage;
import SchemaField = naturalcloudsyncv2.SchemaField;
import FieldType = naturalcloudsyncv2.FieldType;
import QueryRequestMessage = naturalcloudsyncv2.QueryRequestMessage;
import Field = naturalcloudsyncv2.Field;
import SubscribeRequestMessage = naturalcloudsyncv2.SubscribeRequestMessage;
import UnsubscribeRequestMessage = naturalcloudsyncv2.UnsubscribeRequestMessage;
import ServerStatusMessage = naturalcloudsyncv2.ServerStatus;

export class ConversionOptions implements IConversionOptions {
  longs = String;
  defaults = true;
}

const ENC_FIELD_SUFFIX = '#ope';
const CURRENT_MESSAGE_VERSION = 2;
const NATURALBASE_VERSION = 'naturalbase_version';
const TAG = 'ProtoHelper';

export class ProtoHelper {
  public static serializeMessage(
    message: SyncRequest,
    certificateService: CertificateService
  ): object {
    const syncRequestMessage = SyncRequestMessage.create();
    const messageInfo = MessageInfo.create();
    messageInfo.id = message.taskId;
    const store = Store.create();
    store.storeName = message.naturalStoreName || '';
    messageInfo.opStore = store;
    messageInfo.type = message.requestType;
    messageInfo.subType = message.requestSubType as number;
    messageInfo.traceId = message.traceId;
    Logger.info(TAG, `[request] traceId:${message.traceId}, requestType: ${message.requestType}`);

    syncRequestMessage.clientInfo = ProtoHelper.buildClientInfo(certificateService);
    syncRequestMessage.msgInfo = messageInfo;
    syncRequestMessage.clientInfo.enVer = message.encryptionVersion;
    if (messageInfo.type === MessageType.QUERY_SUB) {
      syncRequestMessage.schemas = message.schemas.map(schema => {
        return ProtoHelper.schemaSub2Proto(schema);
      });
    } else {
      const isNeedUpdateSchemaField = messageInfo.type !== MessageType.SCHEMA_NEGOTIATE;
      let isDelete = false;
      if (message instanceof SyncObjectRequest) {
        isDelete = message.operationType === OperationType.SYNC_DELETE;
      }
      syncRequestMessage.schemas = message.schemas.map(schema => {
        return ProtoHelper.schema2Proto(schema, isNeedUpdateSchemaField, isDelete);
      });
    }
    const action = [...ProtoHelper.serializationActions()][messageInfo.type] as any;
    if (!action) {
      Logger.warn(TAG, 'unknown message type' + messageInfo.type);
      throw ExceptionUtil.build(ErrorCode.SYNC_REQUEST_GENERATE_FAIL);
    }
    action.call(null, message, syncRequestMessage);
    if (ProtoHelper.isWebSocketMessageType(message)) {
      return SyncRequestMessage.toObject(syncRequestMessage, new ConversionOptions());
    } else {
      const byteArray = SyncRequestMessage.encode(syncRequestMessage).finish();
      return byteArray.buffer.slice(byteArray.byteOffset, byteArray.byteOffset + byteArray.length);
    }
  }

  public static deserializeMessage(data: any): SyncResult {
    const message = SyncResponseMessage.decode(new Uint8Array(data));
    const msgInfo = message.msgInfo!;
    const type = msgInfo.type as MessageType;
    const taskId = msgInfo.id!;
    const result: SyncResult = {
      storeName: msgInfo.opStore?.storeName || '',
      taskId,
      responseCode: message.resInfo?.resCode || 0,
      type,
      subType: msgInfo.subType || (0 as MessageSubType),
      response: undefined
    };
    if (result.responseCode !== ErrorCode.OK) {
      Logger.warn(TAG, `cloud sync not execute success , responseCode =  ${result.responseCode}`);
    }
    const action = [...ProtoHelper.deserializationActions()][msgInfo.type!];
    if (!action) {
      Logger.warn(TAG, 'unknown message type' + type);
      throw ExceptionUtil.build(ErrorCode.SYNC_REQUEST_GENERATE_FAIL);
    }
    result.response = action.call(null, result, message);
    return result;
  }

  private static parseValue(
    operationData: OperationData[],
    schemas: naturalcloudsyncv2.Schema[]
  ): ObjectWrapper[] {
    if (!operationData || operationData.length === 0) {
      return [];
    }
    const objs: ObjectWrapper[] = [];
    for (const opData of operationData) {
      opData.os.forEach(obj => {
        objs.push(new ObjectWrapper(schemas[obj.i!], obj.fs! as Field[]));
      });
    }
    return objs;
  }

  /**
   * generate schema protobuf object only with primaryKey and version id
   *
   * @param sourceSchema object schema
   */
  private static schemaSub2Proto(sourceSchema: NaturalStoreObjectSchema): Schema {
    const fieldInfo: SchemaField[] = [];
    [...sourceSchema.getFieldInfos().values()].forEach((field: FieldInfo) => {
      if (field.isPrimaryKey) {
        fieldInfo.push(
          SchemaField.fromObject({
            n: field.fieldName,
            t: field.fieldType as number as FieldType
          })
        );
      }
    });
    fieldInfo.push(
      SchemaField.fromObject({
        n: NATURALBASE_VERSION,
        t: FieldType.TYPE_LONG
      })
    );
    return Schema.create({
      n: sourceSchema.name,
      fs: fieldInfo
    });
  }

  private static schema2Proto(
    sourceSchema: NaturalStoreObjectSchema,
    isNeedUpdateSchemaField: boolean,
    isDelete: boolean
  ): Schema {
    const opFields: SchemaField[] = [];
    const fieldInfo: naturalcloudsyncv2.SchemaField[] = [];
    for (const field of [...sourceSchema.getFieldInfos().values()]) {
      const fieldType = field.fieldType as number as FieldType;
      if (isNeedUpdateSchemaField && field.isEncryptField && !isDelete) {
        opFields.push(
          SchemaField.create({
            n: field.fieldName + ENC_FIELD_SUFFIX,
            t: FieldType.TYPE_STRING
          })
        );
      }
      const schemaField = SchemaField.create({
        n: field.fieldName,
        t: isNeedUpdateSchemaField
          ? field.isEncryptField
            ? FieldType.TYPE_BYTE_ARRAY
            : fieldType
          : fieldType,
        p: field.isPrimaryKey,
        e: field.isEncryptField,
        nn: field.isNotNull,
        df: field.hasDefaultValue
      });
      schemaField.defaultValue = field.defaultValue;
      (schemaField as any)[DataTypeMap.get(fieldType)!] = field.defaultValue;
      if (isDelete && !field.isPrimaryKey) {
        continue;
      }
      fieldInfo.push(schemaField);
    }
    return Schema.create({
      n: sourceSchema.name,
      fs: fieldInfo.concat(opFields)
    });
  }

  private static isWebSocketMessageType(message: any): boolean {
    const requestType = message.requestType;
    if (requestType === MessageType.QUERY_SUB || requestType === MessageType.QUERY_UNSUB) {
      return true;
    }
    return (
      requestType === MessageType.ENCRYPTION_TASK &&
      (message.requestSubType === MessageSubType.MONITOR_USER_COMMAND_CHANGE ||
        message.requestSubType === MessageSubType.MONITOR_DATA_KEY_CHANGE)
    );
  }

  private static buildClientInfo(
    certificateService: CertificateService
  ): naturalcloudsyncv2.ClientInfo {
    const context = certificateService.getContext();
    const baseInfo = new Object({
      appVer: context.appVersion,
      msgVer: CURRENT_MESSAGE_VERSION,
      pid: context.productId,
      cid: context.clientId,
      aid: context.appId
    });
    const verifyResult = ClientInfo.verify(baseInfo);
    if (verifyResult != null) {
      Logger.warn(TAG, verifyResult);
      throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
    }
    return ClientInfo.fromObject(baseInfo);
  }

  private static objectUpdateDeserialization(
    result: any,
    response: SyncResponseMessage
  ): CloudObjectSyncResponse {
    return {
      queryId: response.msgInfo!.id!.toString(),
      successNumber: response.updateResMsg!.successRecCount!
    };
  }

  private static objectUpdateSerialization(
    message: SyncObjectRequest,
    requestMessage: SyncRequestMessage
  ) {
    requestMessage.schemas.forEach(schema => {
      ObjectWrapper.addSystemSchemaField(schema as Schema);
    });
    const isDelete = message.operationType === OperationType.SYNC_DELETE;
    const os = ObjectWrapper.buildObjs(message.objList, requestMessage.schemas, isDelete);
    const data = OperationData.create({ os, t: message.operationType, i: 0 });
    requestMessage.opData = [data];
  }

  private static encryptionDeserialization(
    result: any,
    response: SyncResponseMessage
  ): EncryptionResponse {
    const enResInfo = response?.enResInfo;
    if (!enResInfo) {
      Logger.error(
        TAG,
        `ProtoHelper:deserializationActions encryption get invalid encryptionResponseMessage`
      );
      throw ExceptionUtil.build(
        'ProtoHelper:deserializationActions encryption get invalid encryptionResponseMessage'
      );
    }
    return {
      encryptionMessageType: response.msgInfo!.subType as MessageSubType,
      encryptionInfoList: enResInfo.map(info => {
        const encryptInfo = new EncryptInfo();
        encryptInfo.keyStatus = info.keyStatus!;
        encryptInfo.firstSaltValue = info.firstSalt!;
        encryptInfo.secondSaltValue = info.secondSalt!;
        encryptInfo.rootKeyToken = info.rootToken!;
        encryptInfo.dataKeyCipherText = info.cipherText!;
        encryptInfo.oldDataKeyCipherText = info.oldCipherText!;
        encryptInfo.keyVersion = info.keyVer!;
        return encryptInfo;
      })
    };
  }

  private static encryptionSerialization(
    message: EncryptRequest,
    requestMessage: SyncRequestMessage
  ): void {
    requestMessage.msgInfo!.subType = message.requestSubType as number;
    requestMessage.msgInfo!.type = MessageType.ENCRYPTION_TASK;
    requestMessage.enReqInfo = message.requestInfo.map(info => {
      return EncryptionInfo.create({
        keyStatus: info.keyStatus,
        firstSalt: info.firstSaltValue,
        secondSalt: info.secondSaltValue,
        rootToken: info.rootKeyToken,
        cipherText: info.dataKeyCipherText,
        oldCipherText: info.oldDataKeyCipherText,
        keyVer: info.keyVersion
      });
    });
  }

  private static objectQueryDeserialization(
    result: any,
    response: SyncResponseMessage
  ): QueryResponse {
    const queryResMsg = response.queryResMsg!;
    const opData = response.opData as OperationData[];
    const iSchemas = response.schemas as Schema[];
    const objectTypeName = iSchemas[0]?.n;
    return {
      tableName: objectTypeName,
      queryResult: queryResMsg.isComplete!,
      queryType: queryResMsg.queryType as QueryType,
      totalLength: opData.length,
      aggreResult: queryResMsg.aggQueryRes!,
      responseObject: ProtoHelper.parseValue(opData, iSchemas)
    };
  }

  private static objectQuerySerialization(
    message: SyncQueryRequest,
    requestMessage: SyncRequestMessage
  ): void {
    requestMessage.queryReqMsg = QueryRequestMessage.create({
      queryType: message.queryType,
      queryTable: message.tableName,
      queryCond: message.queryCondition
    });
  }

  private static transactionDeserialization(
    result: any,
    response: SyncResponseMessage
  ): TransactionResponse {
    return {
      transactionId: response.msgInfo!.id!.toString(),
      transactionResult: response.resInfo?.resCode as ErrorCode
    };
  }

  private static transactionSerialization(
    message: TransactionRequest,
    requestMessage: SyncRequestMessage
  ): void {
    requestMessage.schemas.forEach(schema => {
      ObjectWrapper.addSystemSchemaField(schema as Schema);
    });
    const schemas: Schema[] = requestMessage.schemas as Schema[];
    // build verifyObject.
    const verifyObj: ObjectWrapper[] = message.verifyObjects;
    const objs = ObjectWrapper.buildVerifyObjs(verifyObj, schemas);
    const verifyData = ObjectWrapper.buildOperationData(objs, OperationType.VERIFY);
    requestMessage.opData.push(...verifyData);
    // build transactionData.
    const transactionData: TransactionData[] = message.transactionDatas;
    ObjectWrapper.buildTransactionData(requestMessage, transactionData, schemas);
  }

  private static querySubscribeDeserialization(
    result: any,
    response: SyncResponseMessage
  ): QuerySubscribeResponse {
    const subscribeResults = response.subResMsg.map(res => {
      return (res as SubscribeResponseMessage).toJSON();
    });
    return { subscribeResults } as QuerySubscribeResponse;
  }

  private static querySubscribeSerialization(
    message: SubscribeRequest,
    requestMessage: SyncRequestMessage
  ): void {
    const opData: OperationData[] = [];
    requestMessage.subReqMsg = message.subscribeDatas.map(data => {
      if (data.snapshotObjs && data.snapshotObjs.length > 0) {
        const [index, schema] = ObjectWrapper.findSchemaIndex(
          requestMessage.schemas,
          data.tableName
        );
        if (index < 0 || !schema) {
          throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
        }
        const os = ObjectWrapper.buildSubObjs(data.snapshotObjs, schema);
        opData.push(OperationData.create({ os }));
      }
      return SubscribeRequestMessage.create({
        subId: data.subscribeId,
        subTable: data.tableName,
        subCond: data.subscribeCondition,
        subStore: data.naturalStoreName
      });
    });
    requestMessage.opData = opData;
  }

  private static queryUnsubscribeDeserialization(
    result: any,
    response: SyncResponseMessage
  ): QueryUnSubscribeResponse {
    const unSubScribeResults = response.unSubResMsg.map(res => {
      return (res as UnsubscribeResponseMessage).toJSON();
    });
    return { unSubScribeResults } as QueryUnSubscribeResponse;
  }

  private static queryUnSubscribeSerialization(
    message: UnSubscribeRequest,
    requestMessage: SyncRequestMessage
  ): void {
    requestMessage.unSubReqMsg = message.unSubscribeDatas.map(data => {
      return UnsubscribeRequestMessage.create({
        subRecId: data.cloudSubRecordId,
        unSubStore: data.naturalStoreName,
        unSubTable: data.tableName,
        subKey: data.cloudSubKey
      });
    });
  }

  private static querySubPushDeserialization(
    result: any,
    response: SyncResponseMessage
  ): QuerySubscribePushResponse {
    const subPushMsg = SubscribePushMessage.toObject(
      response.subPushMsg as SubscribePushMessage,
      new ConversionOptions()
    );
    const schemas = response.schemas;
    const responseObject = response.opData.map(data => {
      const toObject = OperationData.toObject(data as OperationData, new ConversionOptions());
      toObject.tableName = schemas[data.i!].n;
      return toObject;
    });
    const storeName = response.msgInfo?.opStore?.storeName || '';
    return {
      pushSeq: subPushMsg.pushSeq,
      storeName,
      subRecId: subPushMsg.subRecId,
      subKey: subPushMsg.subKey,
      subscribeId: subPushMsg.subId,
      responseObject
    };
  }

  private static emptyFuncDeserialization(result: any, response: SyncResponseMessage): any {
    Logger.error(TAG, 'Call deserialization empty function.');
  }

  private static emptyFuncSerialization(
    message: SyncRequest,
    requestMessage: SyncRequestMessage
  ): any {
    Logger.error(TAG, 'Call serialization empty function.');
  }

  private static deserializationActions() {
    return [
      ProtoHelper.emptyFuncDeserialization,
      ProtoHelper.emptyFuncDeserialization,
      ProtoHelper.emptyFuncDeserialization,
      ProtoHelper.objectUpdateDeserialization,
      ProtoHelper.transactionDeserialization,
      ProtoHelper.objectQueryDeserialization,
      ProtoHelper.querySubscribeDeserialization,
      ProtoHelper.queryUnsubscribeDeserialization,
      ProtoHelper.querySubPushDeserialization,
      ProtoHelper.encryptionDeserialization,
      ProtoHelper.emptyFuncDeserialization
    ];
  }

  private static serializationActions() {
    return [
      ProtoHelper.emptyFuncSerialization,
      ProtoHelper.emptyFuncSerialization,
      ProtoHelper.emptyFuncSerialization,
      ProtoHelper.objectUpdateSerialization,
      ProtoHelper.transactionSerialization,
      ProtoHelper.objectQuerySerialization,
      ProtoHelper.querySubscribeSerialization,
      ProtoHelper.queryUnSubscribeSerialization,
      ProtoHelper.emptyFuncSerialization,
      ProtoHelper.encryptionSerialization,
      ProtoHelper.emptyFuncDeserialization
    ];
  }
}

enum SerializeType {
  PROTOBUF = 3,
  JSON
}

export { MessageType, MessageSubType, QueryType, SerializeType };
