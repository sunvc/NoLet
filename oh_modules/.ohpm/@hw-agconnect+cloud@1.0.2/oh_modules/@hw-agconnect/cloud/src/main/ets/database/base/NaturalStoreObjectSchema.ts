/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { FieldInfo } from '../query/FieldInfo';
import {
  UserRight,
  UserRightNamespace,
  UserRole,
  UserRoleNamespace
} from '../utils/SchemaNamespace';
import { SchemaValidators } from '../utils/SchemaValidators';

const OPE_FIELD_SUFFIX = '#ope';

type PermissionInfo = {
  role: string;
  rights: string[];
};

export enum TableCompare {
  MORE_TABLES = 1,
  LESS_TABLES = 2,
  EQUAL_TABLES = 3,
  DIFF_TABLES = 4
}

export enum FieldCompare {
  MORE_FIELDS = 1,
  LESS_FIELDS = 2,
  EQUAL_FIELDS = 3,
  DIFF_FIELDS = 4,
  INVALID_INDEX = 5,
  INVALID_SCHEMA = 6
}

export class NaturalStoreObjectSchema {
  private name_ = '';
  private primaryKeyList: FieldInfo[] = [];
  private fieldInfos: Map<string, FieldInfo> = new Map();
  private permissions: Map<UserRole, UserRight | number> = new Map();

  constructor(sPermission?: any, sObjectType?: any) {
    if (!sPermission) {
      return;
    }
    this.name_ = sObjectType.objectTypeName;
    sObjectType.fields.forEach((info: any) => {
      const fieldInfo = new FieldInfo(info);
      this.fieldInfos.set(fieldInfo.fieldName, fieldInfo);
      if (fieldInfo.isPrimaryKey) {
        this.primaryKeyList.push(fieldInfo);
      }
    });
    const permissions = sPermission.permissions;
    permissions.forEach((permission: PermissionInfo) => {
      this.permissions.set(
        UserRoleNamespace.getUserRole(permission.role),
        UserRightNamespace.getAllUserRight(permission.rights)
      );
    });
  }

  get name() {
    return this.name_;
  }

  static validateObjectSchema(schema: NaturalStoreObjectSchema): boolean {
    for (const rule of Object.getOwnPropertyNames(SchemaValidators)) {
      SchemaValidators[rule](schema);
    }
    return true;
  }

  compareFields(schema: NaturalStoreObjectSchema | undefined): FieldCompare {
    if (!schema) {
      return FieldCompare.INVALID_SCHEMA;
    }
    const ret = this.compareFieldInfo(schema);
    if (ret === FieldCompare.DIFF_FIELDS) {
      return FieldCompare.INVALID_SCHEMA;
    }
    return ret;
  }

  private compareFieldInfo(schema: NaturalStoreObjectSchema): FieldCompare {
    if (this.fieldInfos.size < schema.fieldInfos.size) {
      return FieldCompare.MORE_FIELDS;
    }
    for (const oldFieldInfo of this.fieldInfos.values()) {
      if (!oldFieldInfo.equalTo(schema.fieldInfos.get(oldFieldInfo.fieldName))) {
        return FieldCompare.DIFF_FIELDS;
      }
    }
    return FieldCompare.EQUAL_FIELDS;
  }

  getFieldInfo(name: string): FieldInfo | undefined {
    return this.fieldInfos.get(name);
  }

  checkPermission(role: UserRole, right: UserRight): boolean {
    const userRight = this.permissions.get(role);
    if (!userRight) {
      return false;
    }
    return UserRightNamespace.checkUserRight(userRight, right);
  }

  getPrimaryKeys(): string[] {
    return [...this.fieldInfos.values()]
      .filter(fieldInfo => {
        return fieldInfo.isPrimaryKey;
      })
      .map(fieldInfo => {
        return fieldInfo.fieldName;
      })
      .sort();
  }

  getPrimaryKeyFieldTypes(): FieldInfo[] {
    return this.primaryKeyList;
  }

  getFieldNames(): string[] {
    return [...this.fieldInfos.keys()];
  }

  hasCompositePrimaryKey(): boolean {
    return this.getPrimaryKeys().length > 1;
  }

  getFieldInfos() {
    return this.fieldInfos;
  }

  setPermission(role: UserRole, right: UserRight) {
    this.permissions.set(role, right);
  }

  isLegalOpeFieldName(opeFieldName: string): boolean {
    return opeFieldName.indexOf(OPE_FIELD_SUFFIX) !== -1;
  }

  isEncryptTable(): boolean {
    for (const value of this.fieldInfos.values()) {
      if (value.isEncryptField) {
        return true;
      }
    }
    return false;
  }

  getEncryptFieldList(): FieldInfo[] {
    return [...this.fieldInfos.values()]
      .filter(fieldInfo => {
        return fieldInfo.isEncryptField;
      })
      .sort();
  }
}
