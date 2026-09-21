/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { ExceptionUtil } from './ExceptionUtil';
import { FieldType, FieldTypeNamespace } from './SchemaNamespace';
import { Utils } from './Utils';
import { SYSTEM_PROPERTY_SET, SYSTEM_TABLE_SET } from '../base/SystemProperties';
import { NaturalStoreObjectSchema } from '../base/NaturalStoreObjectSchema';
import { ValidateResult } from './Constants';
// @ts-ignore
import Long from 'long';

const TAG = 'SchemaValidators';

const NAME_CHECKER = /(^[a-zA-Z][A-Za-z0-9_]{0,28}[A-Za-z0-9]$)|(^[a-zA-Z]$)/;

const TABLE_NAME_MAX_LENGTH = 30;
const TABLE_NAME_MIN_LENGTH = 1;
const FIELD_NAME_MAX_LENGTH = 30;
const FIELD_NAME_MIN_LENGTH = 1;
const MAX_PRIMARY_KEY_FIELDS_COUNT = 5;
const MAX_STRING_TYPE_FIELDS_COUNT = 100;
const MAX_STRING_TYPE_LENGTH = 200;

const FIELD_NOT_SUPPORT_PRIMARYKEY = 'field-not-support-primarykey';
const PRIMARYKEY_REQUIRE = 'primarykey-require';
const NO_NON_DEFAULTVALUE = 'no-non-defaultvalue';
const PRIMARYKEY_COUNT_LIMITATION = 'primarykey-count-limitation';
const STRING_FIELDS_COUNT_LIMITATION = 'string-fields-count-limitation';
const OBJECTTYPE_NAME_VALIDATION = 'objecttype-name-validation';
const NO_SYSTEM_PROPERTY_COLUMN = 'no-system-property-column';
const NO_SYSTEM_TABLE_NAME = 'no-system-table-name';
const FIELD_NAME_VALIDATION = 'field-name-validation';
const FIELD_TYPE_VALIDATION = 'field-type-validation';

const FIELD_NOT_SUPPORT_NOTNULL_VALIDATION = 'field-not-support-notnull-validation';
const FIELD_NOT_SUPPORT_DEFAULT_VALIDATION = 'field-not-support-default-validation';
const FIELD_PRIMARYKEY_NOT_SUPPORT_DEFAULT_VALIDATION =
  'field-primarykey-not-support-default-validation';
const FIELD_DEFAULT_NOT_SUPPORT_NULL_VALIDATION = 'field-default-not-support-null-validation';
const FIELD_AUTOINCREMENT_MUST_NOT_NULL_VALIDATION = 'field-autoincrement-must-not-null-validation';
const OBJECT_HAS_FIELDS_VALIDATION = 'object-has-fields-validation';
const STRING_TEXT_VALUE_LENGTH_VALIDATION = 'string-text-value-length-validation';

const INTEGER_MIN_VALUE = -2147483648;
const INTEGER_MAX_VALUE = 2147483647;
const SHORT_MIN_VALUE = -32768;
const SHORT_MAX_VALUE = 32767;
const BYTE_MIN_VALUE = -128;
const BYTE_MAX_VALUE = 127;
const FLOAT_MIN_VALUE = -3.402823e38;
const FLOAT_MAX_VALUE = 3.402823e38;

const AUTO_INCREMENT_INT_MIN_VALUE = 1;
const AUTO_INCREMENT_LONG_MIN_VALUE = '1';

type SchemaValidatorFn = (schema: NaturalStoreObjectSchema) => void;

export const SchemaValidators: { [key: string]: SchemaValidatorFn } = {};

function addValidator(name: string, validator: SchemaValidatorFn) {
  SchemaValidators[name] = validator;
}

addValidator(OBJECT_HAS_FIELDS_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  if (schema.getFieldInfos().size === 0) {
    throw ExceptionUtil.build(`The object type does not define any field.`);
  }
});

addValidator(FIELD_NOT_SUPPORT_NOTNULL_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (fieldInfo.isNotNull) {
      if (fieldInfo.fieldType === FieldType.Date) {
        throw ExceptionUtil.build(`Date type can not be set as not null value.`);
      } else if (fieldInfo.fieldType === FieldType.ByteArray) {
        throw ExceptionUtil.build(`ByteArray type can not be set as not null value.`);
      }
    }
  }
});

addValidator(FIELD_NOT_SUPPORT_DEFAULT_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (fieldInfo.hasDefaultValue) {
      if (fieldInfo.fieldType === FieldType.Date) {
        throw ExceptionUtil.build(`Date type can not be set as default value.`);
      } else if (fieldInfo.fieldType === FieldType.ByteArray) {
        throw ExceptionUtil.build(`ByteArray type can not be set as default value.`);
      }
    }
  }
});

addValidator(
  FIELD_PRIMARYKEY_NOT_SUPPORT_DEFAULT_VALIDATION,
  (schema: NaturalStoreObjectSchema) => {
    for (const fieldInfo of schema.getFieldInfos().values()) {
      if (fieldInfo.isPrimaryKey && fieldInfo.hasDefaultValue) {
        throw ExceptionUtil.build('The primary key is forbidden to set default value.');
      }
    }
  }
);

addValidator(FIELD_DEFAULT_NOT_SUPPORT_NULL_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (
      fieldInfo.fieldType !== FieldType.IntAutoIncrement &&
      fieldInfo.fieldType !== FieldType.LongAutoIncrement &&
      !fieldInfo.isPrimaryKey &&
      fieldInfo.isNotNull &&
      !fieldInfo.hasDefaultValue
    ) {
      throw ExceptionUtil.build('The field should be set default value while it is set not null.');
    }
  }
});

addValidator(FIELD_AUTOINCREMENT_MUST_NOT_NULL_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (!fieldInfo.isNotNull) {
      if (fieldInfo.fieldType === FieldType.IntAutoIncrement) {
        throw ExceptionUtil.build(`IntAutoIncrement type must be set as not null value.`);
      }
      if (fieldInfo.fieldType === FieldType.LongAutoIncrement) {
        throw ExceptionUtil.build(`LongAutoIncrement type must be set as not null value.`);
      }
    }
  }
});

addValidator(STRING_TEXT_VALUE_LENGTH_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (fieldInfo.fieldType === FieldType.String || fieldInfo.fieldType === FieldType.Text) {
      if (
        !Utils.isNullOrUndefined(fieldInfo.defaultValue) &&
        (fieldInfo.defaultValue as string).length > MAX_STRING_TYPE_LENGTH
      ) {
        throw ExceptionUtil.build('String default value length cannot be greater than 200.');
      }
    }
  }
});

addValidator(NO_SYSTEM_PROPERTY_COLUMN, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (SYSTEM_PROPERTY_SET.has(fieldInfo.fieldName.toLowerCase())) {
      throw ExceptionUtil.build(`Field name ${fieldInfo.fieldName} is invalid.`);
    }
  }
});

addValidator(NO_SYSTEM_TABLE_NAME, (schema: NaturalStoreObjectSchema) => {
  if (SYSTEM_TABLE_SET.has(schema.name?.toLowerCase())) {
    throw ExceptionUtil.build(`The object name is invalid.`);
  }
});

addValidator(FIELD_TYPE_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (!checkFieldType(fieldInfo.fieldType)) {
      throw ExceptionUtil.build(`The type of ${fieldInfo.fieldName} field is not supported.`);
    }
  }
});

addValidator(PRIMARYKEY_REQUIRE, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (fieldInfo.isPrimaryKey) {
      return;
    }
  }
  throw ExceptionUtil.build(`The class does not have primary key.`);
});

addValidator(FIELD_NOT_SUPPORT_PRIMARYKEY, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (
      (fieldInfo.fieldType === FieldType.Date ||
        fieldInfo.fieldType === FieldType.ByteArray ||
        fieldInfo.fieldType === FieldType.Text) &&
      fieldInfo.isPrimaryKey
    ) {
      throw ExceptionUtil.build(
        `${FieldTypeNamespace.toString(fieldInfo.fieldType)} type can not be set as primary key.`
      );
    }
  }
});

addValidator(NO_NON_DEFAULTVALUE, (schema: NaturalStoreObjectSchema) => {
  for (const fieldInfo of schema.getFieldInfos().values()) {
    if (fieldInfo.hasDefaultValue && Utils.isNullOrUndefined(fieldInfo.defaultValue)) {
      throw ExceptionUtil.build(`The field should be set default value while it is set not null.`);
    }
  }
});

addValidator(PRIMARYKEY_COUNT_LIMITATION, (schema: NaturalStoreObjectSchema) => {
  const count = [...schema.getFieldInfos().values()].filter(fieldInfo => {
    return fieldInfo.isPrimaryKey;
  }).length;
  if (count > MAX_PRIMARY_KEY_FIELDS_COUNT) {
    throw ExceptionUtil.build(`The count of primary key exceeds the limit.`);
  }
});

addValidator(STRING_FIELDS_COUNT_LIMITATION, (schema: NaturalStoreObjectSchema) => {
  const count = [...schema.getFieldInfos().values()].filter(fieldInfo => {
    return fieldInfo.fieldType === FieldType.String;
  }).length;
  if (count > MAX_STRING_TYPE_FIELDS_COUNT) {
    throw ExceptionUtil.build(`The count of string type field exceeds the limit.`);
  }
});

addValidator(FIELD_NAME_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  for (const fieldName of schema.getFieldNames()) {
    if (!checkSingleFieldName(fieldName)) {
      throw ExceptionUtil.build(`Field name ${fieldName} is invalid.`);
    }
  }
});

addValidator(OBJECTTYPE_NAME_VALIDATION, (schema: NaturalStoreObjectSchema) => {
  if (!checkObjectTypedName(schema.name)) {
    throw ExceptionUtil.build(`The object name is invalid.`);
  }
});

function checkSingleFieldName(fieldName: string) {
  const length = fieldName.length;
  if (!(length <= FIELD_NAME_MAX_LENGTH && length >= FIELD_NAME_MIN_LENGTH)) {
    Logger.warn(
      TAG,
      `[Rule Invalidation] Field Name length should not exceed ${FIELD_NAME_MAX_LENGTH}`
    );
    return false;
  }
  if (!NAME_CHECKER.test(fieldName)) {
    Logger.warn(TAG, `[Rule Invalidation] ${FIELD_NAME_VALIDATION} => Field Name is invalid.`);
    return false;
  }
  return true;
}

function checkFieldType(fieldType: FieldType) {
  return (
    fieldType === FieldType.Short ||
    fieldType === FieldType.Long ||
    fieldType === FieldType.Integer ||
    fieldType === FieldType.Float ||
    fieldType === FieldType.Double ||
    fieldType === FieldType.String ||
    fieldType === FieldType.Date ||
    fieldType === FieldType.Byte ||
    fieldType === FieldType.ByteArray ||
    fieldType === FieldType.Text ||
    fieldType === FieldType.Boolean ||
    fieldType === FieldType.IntAutoIncrement ||
    fieldType === FieldType.LongAutoIncrement
  );
}

function checkObjectTypedName(tableName: string) {
  if (tableName.length > TABLE_NAME_MAX_LENGTH || tableName.length < TABLE_NAME_MIN_LENGTH) {
    Logger.warn(
      TAG,
      `[Rule Invalidation] Table Name length should not exceed ${TABLE_NAME_MAX_LENGTH}
         and less than ${TABLE_NAME_MIN_LENGTH}.`
    );
    return false;
  }
  if (!NAME_CHECKER.test(tableName)) {
    Logger.warn(TAG, `[Rule Invalidation] Table Name is invalid.`);
    return false;
  }
  return true;
}

type ValidatorFn = (value: any) => ValidateResult;

export const Validators: { [key: number]: ValidatorFn } = {};

function addFileTypeValidator(type: FieldType, validator: ValidatorFn) {
  Validators[type] = validator;
}

addFileTypeValidator(FieldType.Integer, (value: any) => {
  if (!Number.isInteger(value)) {
    return ValidateResult.INVALID_TYPE;
  } else if (value < INTEGER_MIN_VALUE || value > INTEGER_MAX_VALUE) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.String, (value: any) => {
  if (typeof value !== 'string') {
    return ValidateResult.INVALID_TYPE;
  } else if (value.length > MAX_STRING_TYPE_LENGTH) {
    throw ExceptionUtil.build(
      `String type length cannot be greater than ${MAX_STRING_TYPE_LENGTH}.`
    );
  } else if (value.indexOf('\0') !== -1 || value.indexOf('\u0000') !== -1) {
    throw ExceptionUtil.build(
      `The string contains illegal character, use the ByteArray type if you intend to send raw bytes.`
    );
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.Short, (value: any) => {
  if (!Number.isSafeInteger(value)) {
    return ValidateResult.INVALID_TYPE;
  } else if (value < SHORT_MIN_VALUE || value > SHORT_MAX_VALUE) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.Long, (value: any) => {
  if (!Utils.isNullOrUndefined(value) && value.constructor?.name !== 'Long') {
    return ValidateResult.INVALID_TYPE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.Boolean, (value: any) => {
  if (typeof value === 'boolean') {
    return ValidateResult.VALID_VALUE;
  }
  return ValidateResult.INVALID_TYPE;
});
addFileTypeValidator(FieldType.Byte, (value: any) => {
  if (!Number.isSafeInteger(value)) {
    return ValidateResult.INVALID_TYPE;
  } else if (value < BYTE_MIN_VALUE || value > BYTE_MAX_VALUE) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.Float, (value: any) => {
  if (typeof value !== 'number') {
    return ValidateResult.INVALID_TYPE;
  } else if (value < FLOAT_MIN_VALUE || value > FLOAT_MAX_VALUE) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.Double, (value: any) => {
  if (typeof value !== 'number') {
    return ValidateResult.INVALID_TYPE;
  } else if (!Number.isFinite(value)) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.ByteArray, (value: any) => {
  if (value instanceof ArrayBuffer || value instanceof Uint8Array) {
    return ValidateResult.VALID_VALUE;
  }
  return ValidateResult.INVALID_TYPE;
});
addFileTypeValidator(FieldType.Date, (value: any) => {
  if (value instanceof Date) {
    if (isNaN(value.getTime())) {
      return ValidateResult.INVALID_VALUE;
    }
    return ValidateResult.VALID_VALUE;
  }
  return ValidateResult.INVALID_TYPE;
});
addFileTypeValidator(FieldType.Text, (value: any) => {
  if (typeof value === 'string') {
    if (value.indexOf('\0') !== -1 || value.indexOf('\u0000') !== -1) {
      throw ExceptionUtil.build(
        `The string contains illegal character, use the ByteArray type if you intend to send raw bytes.`
      );
    }
    return ValidateResult.VALID_VALUE;
  }
  return ValidateResult.INVALID_TYPE;
});
addFileTypeValidator(FieldType.IntAutoIncrement, (value: any) => {
  if (!Number.isInteger(value)) {
    return ValidateResult.INVALID_TYPE;
  } else if (value < AUTO_INCREMENT_INT_MIN_VALUE || value > INTEGER_MAX_VALUE) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
addFileTypeValidator(FieldType.LongAutoIncrement, (value: any) => {
  if (!Utils.isNullOrUndefined(value) && value.constructor?.name !== 'Long') {
    return ValidateResult.INVALID_TYPE;
  } else if ((value as Long).compare(Long.fromString(AUTO_INCREMENT_LONG_MIN_VALUE)) === -1) {
    return ValidateResult.INVALID_VALUE;
  }
  return ValidateResult.VALID_VALUE;
});
