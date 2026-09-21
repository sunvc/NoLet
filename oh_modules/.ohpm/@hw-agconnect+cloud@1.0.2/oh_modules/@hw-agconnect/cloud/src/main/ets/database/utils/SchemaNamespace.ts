/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

enum FieldType {
  Boolean = 1,
  Byte = 2,
  Short = 3,
  Integer = 4,
  Long = 5,
  Float = 6,
  Double = 7,
  ByteArray = 8,
  String = 9,
  Date = 10,
  Text = 11,
  IntAutoIncrement = 12,
  LongAutoIncrement = 13,
  Unknown = 14
}

namespace FieldTypeNamespace {
  export function getFieldType(type: string): FieldType {
    const fieldType = (FieldType as any)[type];
    if (!fieldType) {
      return FieldType.Unknown;
    }
    return fieldType;
  }

  export function valueOf(type: FieldType): number {
    return type;
  }

  export function toString(type: number): string {
    switch (type) {
      case 1:
        return 'Boolean';
      case 2:
        return 'Byte';
      case 3:
        return 'Short';
      case 4:
        return 'Integer';
      case 5:
        return 'Long';
      case 6:
        return 'Float';
      case 7:
        return 'Double';
      case 8:
        return 'ByteArray';
      case 9:
        return 'String';
      case 10:
        return 'Date';
      case 11:
        return 'Text';
      case 12:
        return 'IntAutoIncrement';
      case 13:
        return 'LongAutoIncrement';
      default:
        return 'Unknown';
    }
  }
}

enum UserRole {
  World = 'World',
  Authenticated = 'Authenticated',
  Creator = 'Creator',
  Administrator = 'Administrator'
}

namespace UserRoleNamespace {
  export function getUserRole(role: string) {
    const userRole = (UserRole as any)[role];
    if (!userRole) {
      return UserRole.World;
    }
    return userRole;
  }
}

enum UserRight {
  None = 0,
  Read = 1,
  Upsert = 2,
  Delete = 4
}

namespace UserRightNamespace {
  export function getUserRight(right: string) {
    switch (right) {
      case 'Read':
        return UserRight.Read;
      case 'Upsert':
        return UserRight.Upsert;
      case 'Delete':
        return UserRight.Delete;
      default:
        return UserRight.None;
    }
  }

  export function getAllUserRight(rights: string[]) {
    let right = 0;
    rights.forEach(r => {
      const cr = UserRightNamespace.getUserRight(r);
      right = right | cr;
    });
    return right;
  }

  export function checkUserRight(expect: UserRight | number, right: UserRight) {
    return (expect & right) !== 0;
  }

  export function composeUserRight(rights: number[]) {
    let right = 0;
    rights.forEach(r => {
      right = right | r;
    });
    return right;
  }
}

export {
  UserRight,
  UserRole,
  FieldType,
  UserRightNamespace,
  UserRoleNamespace,
  FieldTypeNamespace
};
