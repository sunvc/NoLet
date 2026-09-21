/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { FieldInfo } from '../query/FieldInfo';
import { FieldType } from '../utils/SchemaNamespace';
import { SchemaUtils } from '../utils/SchemaUtils';
import { Utils } from '../utils/Utils';
import { NaturalStoreObjectSchema } from './NaturalStoreObjectSchema';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { Serializers, Deserializers } from '../utils/Serializable';
import { Calculators } from '../utils/Calculators';

// This is for 64bit JVM Object.
const EMPTY_OBJECT_MEMORY_USAGE = 16;

const TAG = 'DataModelProcessor';

class DataModelProcessor {
  private name_: string;
  private primaryKeys: FieldInfo[];
  private fieldsInfos: Map<string, FieldInfo>;

  constructor(schema: NaturalStoreObjectSchema) {
    this.fieldsInfos = schema.getFieldInfos();
    this.primaryKeys = schema.getPrimaryKeyFieldTypes();
    this.name_ = schema.name;
  }

  get name() {
    return this.name_;
  }

  getFieldsInfos() {
    return this.fieldsInfos;
  }

  getFieldInfo(fieldName: string) {
    return this.fieldsInfos.get(fieldName);
  }

  getPrimaryKeys() {
    return this.primaryKeys;
  }

  deserialize<T>(clz: new () => T, obj: any) {
    const data = new clz() as any;
    for (const key of this.fieldsInfos.keys()) {
      const fieldInfo = this.fieldsInfos.get(key);
      if (!fieldInfo) {
        Logger.warn(TAG, `DataModelHelper: deserialize invalid fieldInfo.`);
        continue;
      }
      const fieldType = fieldInfo!.fieldType;
      if (obj[key] === null) {
        data[key] = undefined;
      } else if (fieldInfo?.isEncryptField) {
        data[key] = obj[key];
      } else {
        data[key] = Deserializers[fieldType] ? Deserializers[fieldType](obj[key]) : obj[key];
      }
    }
    return data;
  }

  serialize(object: any) {
    const data: any = {};
    for (const key of this.fieldsInfos.keys()) {
      const fieldInfo = this.fieldsInfos.get(key);
      if (!fieldInfo) {
        Logger.warn(TAG, `DataModelHelper: serialize invalid fieldInfo key.`);
        continue;
      }
      const fieldType = fieldInfo!.fieldType;
      if (object[key] === null) {
        data[key] = undefined;
      } else if (fieldInfo?.isEncryptField) {
        data[key] = object[key];
        if (fieldInfo?.opeName && object[fieldInfo?.opeName]) {
          const opeName = fieldInfo?.opeName;
          data[opeName] = Serializers[FieldType.String]
            ? Serializers[FieldType.String](object[opeName])
            : object[opeName];
        }
      } else {
        data[key] = Serializers[fieldType] ? Serializers[fieldType](object[key]) : object[key];
      }
    }
    return data;
  }

  serializeDeletedObject(object: any) {
    const data: any = {};
    for (const key of this.fieldsInfos.keys()) {
      const fieldInfo = this.fieldsInfos.get(key);
      if (!fieldInfo) {
        Logger.warn(TAG, `DataModelHelper: serializeDeletedObject invalid fieldInfo key.`);
        continue;
      }
      if (fieldInfo!.isPrimaryKey) {
        data[key] = Serializers[fieldInfo!.fieldType]
          ? Serializers[fieldInfo!.fieldType](object[key])
          : object[key];
      }
    }
    return data;
  }

  calculate(object: any) {
    let memorySize = 0;
    for (const key of this.fieldsInfos.keys()) {
      const fieldType = this.fieldsInfos.get(key)!.fieldType;
      if (Utils.isNullOrUndefined(object[key])) {
        continue;
      }
      const size = Calculators[fieldType] ? Calculators[fieldType](object[key]) : 0;
      memorySize = memorySize + size;
    }
    return memorySize;
  }

  validate(object: any) {
    const properties = Object.getOwnPropertyNames(object);
    if (properties.length !== this.fieldsInfos.size) {
      Logger.warn(
        TAG,
        `The number of fields in the object is inconsistent with that in the schema.`
      );
      return false;
    }
    for (const name of properties) {
      if (!this.validateFieldValue(this.fieldsInfos.get(name), object[name])) {
        return false;
      }
    }
    return true;
  }

  private validateFieldValue(info: FieldInfo | undefined, value: unknown): boolean {
    if (!info) {
      Logger.warn(TAG, `The field info not found in DataModelHelper.`);
      return false;
    }

    if (!Utils.isNullOrUndefined(value)) {
      SchemaUtils.validateFieldValue(info.fieldType, value);
    }
    return true;
  }
}

export class DataModelHelper {
  private processors: Map<string, DataModelProcessor> = new Map();

  public constructor(schemas: Map<string, NaturalStoreObjectSchema>) {
    this.loadAppSchema(schemas);
  }

  private loadAppSchema(schemas: Map<string, NaturalStoreObjectSchema>) {
    for (const schema of schemas.values()) {
      const processor = new DataModelProcessor(schema);
      this.processors.set(processor.name, processor);
    }
  }

  deserialize<T>(clz: new () => T, obj: object): T {
    const className = Utils.getClassName(clz);
    if (!(Utils.isClass(clz) && this.containProcessor(className))) {
      throw ExceptionUtil.build('clz is not valid data model class!');
    }
    if (!Utils.isNotNullObject(obj)) {
      throw ExceptionUtil.build('object is not valid data model object!');
    }
    return this.processors.get(className)!.deserialize(clz, obj);
  }

  serialize(clz: any, obj: object): object {
    const className = Utils.getClassName(clz);
    if (!(Utils.isClass(clz) && this.containProcessor(className))) {
      throw ExceptionUtil.build('clz is not valid data model class!');
    }
    if (!Utils.isNotNullObject(obj)) {
      throw ExceptionUtil.build('object is not valid data model object!');
    }
    return this.processors.get(className)!.serialize(obj);
  }

  serializeDeletedObject(clz: any, obj: object): object {
    const className = Utils.getClassName(clz);
    if (!(Utils.isClass(clz) && this.containProcessor(className))) {
      throw ExceptionUtil.build('serializeDeletedObject: clz is not valid data model class!');
    }
    if (!Utils.isNotNullObject(obj)) {
      throw ExceptionUtil.build('serializeDeletedObject: object is not valid data model object!');
    }
    return this.processors.get(className)!.serializeDeletedObject(obj);
  }

  calculate(clz: any, obj: object): number {
    const className = Utils.getClassName(clz);
    if (!(Utils.isClass(clz) && this.containProcessor(className))) {
      throw ExceptionUtil.build('clz is not valid data model class!');
    }
    if (!Utils.isNotNullObject(obj)) {
      throw ExceptionUtil.build('object is not valid data model object!');
    }
    return this.processors.get(className)!.calculate(obj) + EMPTY_OBJECT_MEMORY_USAGE;
  }

  calculateObject<T>(object: T): number {
    if (!Utils.isNotNullObject(object)) {
      throw ExceptionUtil.build(`The object is invalid data model.`);
    }
    const className = Utils.getClassName(object);
    if (!this.containProcessor(className)) {
      throw ExceptionUtil.build(`The object type is not loaded yet.`);
    }
    const processor = this.processors.get(className)!;
    return processor.calculate(object) + EMPTY_OBJECT_MEMORY_USAGE;
  }

  getFieldInfosByClassName(className: string) {
    const processor = this.processors.get(className);
    if (processor) {
      return processor.getFieldsInfos();
    }
    return new Map<string, FieldInfo>();
  }

  getFieldInfoByName(className: string, fieldName: string) {
    const processor = this.processors.get(className);
    if (processor) {
      return processor.getFieldInfo(fieldName);
    }
    return undefined;
  }

  getPrimaryKeyByClassName(className: string) {
    const processor = this.processors.get(className);
    if (processor) {
      return processor.getPrimaryKeys();
    }
    return [] as FieldInfo[];
  }

  validate(object: any): boolean {
    if (Utils.isNotNullObject(object)) {
      const className = Utils.getClassName(object);
      const processor = this.processors.get(className);
      return processor ? processor.validate(object) : false;
    }
    return false;
  }

  private containProcessor(className: string): boolean {
    return this.processors.has(className);
  }
}
