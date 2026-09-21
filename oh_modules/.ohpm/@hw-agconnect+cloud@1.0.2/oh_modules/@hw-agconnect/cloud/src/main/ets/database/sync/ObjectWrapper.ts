/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { naturalcloudsyncv2 } from '../generated/syncmessage';
import { ConversionOptions } from './ProtoHelper';
// @ts-ignore
import Long from 'long';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { ErrorCode } from '../utils/ErrorCode';
import { OperationType, ServerPushOperationType } from './utils/MessageType';
import { TransactionData } from './request/TransactionRequest';

import Field = naturalcloudsyncv2.Field;
import Schema = naturalcloudsyncv2.Schema;
import SchemaField = naturalcloudsyncv2.SchemaField;
import FieldType = naturalcloudsyncv2.FieldType;
import OperationData = naturalcloudsyncv2.OperationData;
import SyncRequestMessage = naturalcloudsyncv2.SyncRequestMessage;

const DEFAULT_CREATOR = '';
const DEFAULT_OBJECT_VERSION = 0;
const DEFAULT_OBJECT_TYPE_NAME = '';
const CLASSNAME_PROPERTY = 'className';
const ENC_FIELD_SUFFIX = '#ope';
const naturalbaseCreator = 'naturalbase_creator';
const naturalbaseVersion = 'naturalbase_version';
const naturalbaseDeleted = 'naturalbase_deleted';
const TAG = 'ObjectWrapper';

export class ObjectWrapper {
  public readonly creator: string | null | undefined = DEFAULT_CREATOR;
  public readonly objectVersion: number | undefined = DEFAULT_OBJECT_VERSION;
  public objectTypeName: string = DEFAULT_OBJECT_TYPE_NAME;
  private userObject?: any;
  public readonly schema?: naturalcloudsyncv2.Schema;
  private readonly values: naturalcloudsyncv2.Field[];
  public readonly operationType?: ServerPushOperationType;

  constructor(schema: Schema, fields: naturalcloudsyncv2.Field[], operationType?: number) {
    this.values = fields;
    this.operationType = operationType as ServerPushOperationType;
    if (operationType === ServerPushOperationType.DELETE) {
      // deleted push data fields only has object version field.
      if (!fields || fields.length === 0 || !fields[0].l) {
        Logger.warn(TAG, `invalid object version of delete wrapper object`);
        return;
      }
      this.objectVersion = fields[0].l.toNumber();
    } else {
      this.schema = Schema.fromObject(Schema.toObject(schema, new ConversionOptions()));
      ObjectWrapper.addSystemSchemaField(this.schema);
      this.objectTypeName = schema.n;
      this.creator =
        fields[schema.fs.indexOf(schema.fs.find(field => field.n === naturalbaseCreator)!)]?.s;
      this.objectVersion =
        fields[
          schema.fs.indexOf(schema.fs.find(field => field.n === naturalbaseVersion)!)
        ]?.l?.toNumber();
    }
  }

  public static findSchemaIndex(
    schemas: naturalcloudsyncv2.ISchema[],
    schemaName: string
  ): [number, Schema] {
    let schemaIndex = -1;
    const schema = schemas.find((sc, index) => {
      if (sc.n === schemaName) {
        schemaIndex = index;
        return true;
      }
      return false;
    }) as Schema;
    return [schemaIndex, schema];
  }

  static addSystemSchemaField(schema: Schema) {
    const hasCreator = schema.fs.find(e => e.n === naturalbaseCreator);
    const hasVersion = schema.fs.find(e => e.n === naturalbaseVersion);
    const hasDeleted = schema.fs.find(e => e.n === naturalbaseDeleted);
    if (!hasCreator) {
      schema.fs.push(SchemaField.create({ n: naturalbaseCreator, t: FieldType.TYPE_STRING }));
    }
    if (!hasVersion) {
      schema.fs.push(SchemaField.create({ n: naturalbaseVersion, t: FieldType.TYPE_LONG }));
    }
    if (!hasDeleted) {
      schema.fs.push(SchemaField.create({ n: naturalbaseDeleted, t: FieldType.TYPE_BOOLEAN }));
    }
  }

  public static buildObjs(
    data: any[],
    schemas: naturalcloudsyncv2.ISchema[],
    isDelete: boolean
  ): naturalcloudsyncv2.Obj[] {
    const result: any[] = [];
    for (const record of data) {
      const objectTypeName = ObjectWrapper.getClassName(record);
      const [index, schema] = this.findSchemaIndex(schemas, objectTypeName);
      if (index < 0 || !schema) {
        throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
      }
      result.push(this.buildObj(record, schema, isDelete, index));
    }
    return result;
  }

  public static buildVerifyObjs(
    verifyObj: ObjectWrapper[],
    schemas: Schema[]
  ): naturalcloudsyncv2.Obj[] {
    const objs: naturalcloudsyncv2.Obj[] = [];
    for (const ow of verifyObj) {
      const [index, schema] = ObjectWrapper.findSchemaIndex(schemas, ow.objectTypeName);
      const items = ow.toSyncObject();
      if (index < 0 || !schema) {
        throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
      }
      items.i = index;
      items.fs.push(Field.create({ n: false, bl: false }));
      for (const field of schema.fs) {
        const name = field.n!;
        if (name.indexOf(ENC_FIELD_SUFFIX) > -1) {
          items.fs.splice(-3, 0, Field.create({ n: true }));
        }
      }
      objs.push(items);
    }
    return objs;
  }

  public static buildTransactionData(
    requestMessage: SyncRequestMessage,
    transactionData: TransactionData[],
    schemas: Schema[]
  ) {
    for (const transactionDatum of transactionData) {
      const objectTypeName = transactionDatum.objectTypeName;
      const operationType = transactionDatum.operationType;
      const isDelete = transactionDatum.operationType === OperationType.SYNC_DELETE;
      const objects = transactionDatum.objects;
      const [index, schema] = this.findSchemaIndex(schemas, objectTypeName);
      if (index < 0 || !schema) {
        throw ExceptionUtil.build(ErrorCode.INPUT_PARAMETER_INVALID);
      }
      const os = this.buildObjs(objects, schemas, isDelete);
      const optData = this.buildOperationData(os, operationType);
      requestMessage.opData.push(...optData);
    }
  }

  public static buildOperationData(
    objs: naturalcloudsyncv2.Obj[],
    operationType: OperationType
  ): OperationData[] {
    const result: OperationData[] = [];
    const groupBy: naturalcloudsyncv2.Obj[][] = this.groupBy(objs, 'i');
    for (const groups of groupBy) {
      const index = groups[0]?.i;
      result.push(OperationData.create({ os: groups, t: operationType, i: index }));
    }
    return result;
  }

  public static groupBy(datas: naturalcloudsyncv2.Obj[], key: string): naturalcloudsyncv2.Obj[][] {
    const result: any = {};
    for (let i = 0; i < datas.length; i++) {
      const data: any = datas[i] as any;
      const datumElement = data[key];
      result[datumElement] = result[datumElement] || [];
      result[datumElement].push(data);
    }
    const objs: any[] = [];
    for (const [index, value] of Object.entries(result)) {
      objs.push(value);
    }
    return objs as naturalcloudsyncv2.Obj[][];
  }

  /**
   * build resubscribe objects, return protobuf objects
   *
   * @param data ObjectWrapper objects
   * @param schema schema with primaryKey and versionId
   * @return protobuf objects
   */
  public static buildSubObjs(
    data: ObjectWrapper[],
    schema: naturalcloudsyncv2.ISchema
  ): naturalcloudsyncv2.Obj[] {
    const result: naturalcloudsyncv2.Obj[] = [];
    for (const objWrapper of data) {
      const record = objWrapper.getUserObject();
      const fields: Field[] = [];
      for (const schemaField of schema.fs!) {
        if (schemaField.n === naturalbaseVersion) {
          if (objWrapper.objectVersion != null) {
            fields.push(Field.create({ l: Long.fromNumber(objWrapper.objectVersion) }));
          }
          continue;
        }
        const field = Field.create() as any;
        const type: naturalcloudsyncv2.FieldType = schemaField.t!;
        field[DataTypeMap.get(type)!] = record[schemaField.n!];
        fields.push(field);
      }
      result.push(naturalcloudsyncv2.Obj.create({ fs: fields }));
    }
    return result;
  }

  private static buildObj(
    data: any,
    schema: naturalcloudsyncv2.Schema,
    isDelete: boolean,
    index: number
  ): naturalcloudsyncv2.Obj {
    const fs: Field[] = [];
    for (const iSchemaField of schema.fs) {
      const fieldName = iSchemaField.n!;
      const isPrimaryKey = iSchemaField.p;
      if (fieldName === naturalbaseCreator) {
        fs.push(Field.create({ n: true }));
      } else if (fieldName === naturalbaseVersion) {
        fs.push(Field.create({ n: true }));
      } else if (fieldName === naturalbaseDeleted) {
        fs.push(Field.create({ n: false, bl: isDelete }));
      } else {
        const value = data[fieldName];
        const type: naturalcloudsyncv2.FieldType = iSchemaField.t!;
        let isNull;
        if (!isPrimaryKey && isDelete) {
          isNull = true;
        } else {
          isNull = ObjectWrapper.isNullValue(value, type);
        }
        const field = Field.create({ n: isNull }) as any;
        if (!isNull) {
          field[DataTypeMap.get(type)!] = type === FieldType.TYPE_DATE ? value.getTime() : value;
        }
        fs.push(field);
      }
    }
    return naturalcloudsyncv2.Obj.create({ fs, i: index });
  }

  private static isNullValue(value: any, type: FieldType): boolean {
    if (value === null || value === undefined) {
      return true;
    }
    if (type === FieldType.TYPE_DATE) {
      return !(value instanceof Date);
    } else if (type === FieldType.TYPE_LONG) {
      return value?.constructor?.name !== 'Long';
    } else {
      return false;
    }
  }

  static getClassName<T extends object>(record: T): string {
    return (record.constructor as any)[CLASSNAME_PROPERTY]
      ? (record.constructor as any)[CLASSNAME_PROPERTY]
      : record.constructor.name;
  }

  public toSyncObject(): naturalcloudsyncv2.Obj {
    const syncObject = naturalcloudsyncv2.Obj.create();
    syncObject.fs = this.values;
    return syncObject;
  }

  public setObjectTypeName<T>(clz: new () => T) {
    this.objectTypeName = (clz as any).className ? (clz as any).className : clz.name;
  }

  public getUserObject() {
    return this.userObject;
  }

  public setUserObject(object: any) {
    this.userObject = object;
  }

  public getObject(): object {
    const schema = Schema.toObject(this.schema as Schema, new ConversionOptions());
    const values = this.values.map(value => {
      return Field.toObject(value, { longs: Long, defaults: true });
    });
    const obj = {} as any;
    for (let i = 0; i < values.length; i++) {
      const field = schema.fs![i];
      const name = field.n!;
      const type = field.e ? FieldType.TYPE_BYTE_ARRAY : field.t;
      const value = values[i] as any;
      const isNull = value.n;
      const property = DataTypeMap.get(type)!;
      obj[name] = isNull ? undefined : value[property];
    }
    return obj;
  }

  public clone(): ObjectWrapper {
    const values: any[] = [];
    for (const field of this.values) {
      const toObject = Field.toObject(field, new ConversionOptions());
      values.push(Field.fromObject(toObject));
    }
    return new ObjectWrapper(this.schema!, values);
  }

  public isValidVersion(): boolean {
    return this.objectVersion !== DEFAULT_OBJECT_VERSION;
  }
}

export const DataTypeMap = new Map<any, any>();

DataTypeMap.set(FieldType.TYPE_BOOLEAN, 'bl');
DataTypeMap.set(FieldType.TYPE_BYTE, 'b');
DataTypeMap.set(FieldType.TYPE_BYTE_ARRAY, 'ba');
DataTypeMap.set(FieldType.TYPE_DATE, 'l');
DataTypeMap.set(FieldType.TYPE_DOUBLE, 'd');
DataTypeMap.set(FieldType.TYPE_FLOAT, 'f');
DataTypeMap.set(FieldType.TYPE_INT32, 'i');
DataTypeMap.set(FieldType.TYPE_LONG, 'l');
DataTypeMap.set(FieldType.TYPE_SHORT, 'st');
DataTypeMap.set(FieldType.TYPE_STRING, 's');
DataTypeMap.set(FieldType.TYPE_TEXT, 's');
DataTypeMap.set(FieldType.TYPE_AUTO_INCREMENT_INT, 'i');
DataTypeMap.set(FieldType.TYPE_AUTO_INCREMENT_LONG, 'l');
