/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { FieldType, FieldTypeNamespace } from '../utils/SchemaNamespace';
// @ts-ignore
import Long from 'long';

const DEFAULTVALUE_PROPERTY = 'defaultValue';
const BOOLEAN_TRUE_STRING = 'true';

export class FieldInfo {
  private isNeedEncrypt = false;
  private notNull = false;
  private belongPrimaryKey = false;

  public fieldName = '';
  public fieldType: FieldType = FieldType.Unknown;
  public signature = -1;
  public hasDefaultValue = false;
  public defaultValue: any;
  public opeName = '';

  constructor(info?: any) {
    if (!info) {
      return;
    }
    this.parseFieldInfo(info);
    this.signature = FieldInfo.hash(this.fieldName);
  }

  private static hash(value: string | number) {
    const str = '' + value;
    let hash = 5381;
    let index = str.length;
    while (index) {
      hash = (hash * 33) ^ str.charCodeAt(--index);
    }
    return Math.abs(hash >>> 0);
  }

  private parseFieldInfo(info: any) {
    this.isNeedEncrypt = info.isNeedEncrypt;
    this.fieldName = info.fieldName;
    this.notNull = info.notNull;
    this.belongPrimaryKey = info.belongPrimaryKey;
    this.fieldType = FieldTypeNamespace.getFieldType(info.fieldType);
    if (this.isEncryptField && info.fieldName !== null && info.fieldName !== undefined) {
      this.opeName =
        info.fieldName.indexOf('#ope') === -1 ? info.fieldName + '#ope' : info.fieldName;
    }
    if (Object.prototype.hasOwnProperty.call(info, DEFAULTVALUE_PROPERTY)) {
      this.setDefaultValue(info.defaultValue);
    }
  }

  private setDefaultValue(defaultValue: any) {
    this.hasDefaultValue = true;
    switch (this.fieldType) {
      case FieldType.Boolean:
        this.defaultValue = defaultValue === BOOLEAN_TRUE_STRING;
        break;
      case FieldType.Byte:
      case FieldType.Double:
      case FieldType.Float:
      case FieldType.Integer:
      case FieldType.Short:
        this.defaultValue = Number(defaultValue);
        break;
      case FieldType.Long:
        this.defaultValue = Long.fromString(defaultValue);
        break;
      case FieldType.String:
      case FieldType.Text:
        this.defaultValue = defaultValue;
        break;
      default:
        break;
    }
  }

  get isEncryptField() {
    return this.isNeedEncrypt;
  }

  get isNotNull() {
    return this.notNull;
  }

  get isPrimaryKey() {
    return this.belongPrimaryKey;
  }

  equalTo(fieldInfo: FieldInfo | undefined): boolean {
    if (!fieldInfo) {
      return false;
    }
    const keys = Object.getOwnPropertyNames(fieldInfo);
    for (const key of keys) {
      if ((this as any)[key] instanceof Long && (fieldInfo as any)[key] instanceof Long) {
        const long1 = (this as any)[key] as Long;
        const long2 = (fieldInfo as any)[key] as Long;
        if (!long1.equals(long2)) {
          return false;
        }
      } else if ((this as any)[key] !== (fieldInfo as any)[key]) {
        return false;
      }
    }
    return true;
  }
}
