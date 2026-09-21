/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { SchemaValidators, Validators } from './SchemaValidators';
import { ValidateResult } from './Constants';
import { ExceptionUtil } from './ExceptionUtil';
import { FieldType, FieldTypeNamespace } from './SchemaNamespace';
import {
  FieldCompare,
  NaturalStoreObjectSchema,
  TableCompare
} from '../base/NaturalStoreObjectSchema';
import { ErrorCode } from './ErrorCode';

const TAG = 'SchemaUtils';

export class SchemaUtils {
  static validateFieldValue(fieldType: FieldType, value: unknown): void {
    const result = Validators[fieldType](value);
    if (result === ValidateResult.INVALID_TYPE) {
      throw ExceptionUtil.build(`The field type mismatches the value type.`);
    }
    if (result === ValidateResult.INVALID_VALUE) {
      const fieldTypeString = FieldTypeNamespace.toString(fieldType);
      throw ExceptionUtil.build(`The value for a ${fieldTypeString} column is invalid.`);
    }
  }

  static validateFieldValueForQuery(fieldType: FieldType, value: unknown): void {
    if (fieldType === FieldType.LongAutoIncrement) {
      fieldType = FieldType.Long;
    } else if (fieldType === FieldType.IntAutoIncrement) {
      fieldType = FieldType.Integer;
    }
    this.validateFieldValue(fieldType, value);
  }

  static validateObjectSchema(schema: NaturalStoreObjectSchema): boolean {
    for (const rule of Object.getOwnPropertyNames(SchemaValidators)) {
      SchemaValidators[rule](schema);
    }
    return true;
  }

  static compareSchemas(
    curVersion: number,
    curSchemas: Map<string, NaturalStoreObjectSchema>,
    loadedVersion: number,
    loadedSchemas: Map<string, NaturalStoreObjectSchema>
  ): boolean {
    if (curVersion > loadedVersion) {
      Logger.error(
        TAG,
        `compareSchemas: Object version downgrade is not support.` +
          ` current version: ${curVersion}`
      );
      throw ExceptionUtil.build(ErrorCode.OBJECTTYPE_VERSION_NOT_ALLOW_DOWNGRADE);
    }
    const ret = this.compareTables(curSchemas, loadedSchemas);
    if (curVersion === loadedVersion) {
      if (ret === TableCompare.EQUAL_TABLES) {
        Logger.warn(TAG, `compareSchemas: ObjectType version and ObjectType has not changed.`);
        return true;
      }
      Logger.error(
        TAG,
        `compareSchemas: ObjectType version has not changed, but ObjectType has changed.`
      );
      throw ExceptionUtil.build(ErrorCode.OBJECT_TYPE_INFO_IS_INVALID);
    }
    switch (ret) {
      case TableCompare.EQUAL_TABLES:
        Logger.error(
          TAG,
          `compareSchemas: ObjectType version has changed, but ObjectType has not changed.`
        );
        throw ExceptionUtil.build(ErrorCode.OBJECT_TYPE_INFO_IS_INVALID);
      case TableCompare.LESS_TABLES:
        Logger.error(TAG, `compareSchemas: Remove ObjectType is not supported.`);
        throw ExceptionUtil.build(ErrorCode.OBJECT_TYPE_INFO_IS_INVALID);
      case TableCompare.DIFF_TABLES:
        Logger.error(TAG, `compareSchemas: cannot modify existing schema when upgrade.`);
        throw ExceptionUtil.build(ErrorCode.OBJECT_TYPE_INFO_IS_INVALID);
      case TableCompare.MORE_TABLES:
      default:
        return false;
    }
  }

  static compareTables(
    curSchemas: Map<string, NaturalStoreObjectSchema>,
    loadedSchemas: Map<string, NaturalStoreObjectSchema>
  ): TableCompare {
    if (curSchemas.size > loadedSchemas.size) {
      return TableCompare.LESS_TABLES;
    }

    let hasMoreFields = false;
    for (const schema of curSchemas.values()) {
      const name = schema.name;
      const item = loadedSchemas.get(name);
      // only MORE_FIELDS and EQUAL_FIELDS is valid
      const ret = schema.compareFields(item);
      if (ret === FieldCompare.MORE_FIELDS) {
        hasMoreFields = true;
      } else if (ret === FieldCompare.EQUAL_FIELDS) {
        continue;
      } else {
        return TableCompare.DIFF_TABLES;
      }
    }
    if (curSchemas.size < loadedSchemas.size || hasMoreFields) {
      return TableCompare.MORE_TABLES;
    }
    return TableCompare.EQUAL_TABLES;
  }
}
