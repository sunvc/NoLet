/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { UserRight, UserRole } from '../utils/SchemaNamespace';
import { DataModelHelper } from './DataModelHelper';
import { NaturalStoreObjectSchema } from './NaturalStoreObjectSchema';

export class DefaultNaturalStore {
  private version = -1;
  private schemas: Map<string, NaturalStoreObjectSchema> = new Map();
  private dataModelHelper!: DataModelHelper;

  constructor() {}

  public createObjectType(version: number, schemas: Map<string, NaturalStoreObjectSchema>): void {
    this.version = version;
    this.schemas = schemas;
    this.dataModelHelper = new DataModelHelper(schemas);
  }

  public getAppSchema(): Map<string, NaturalStoreObjectSchema> {
    return this.schemas;
  }

  public getAppVersion(): number {
    return this.version;
  }

  public getSchemaToNegotiate(): NaturalStoreObjectSchema[] {
    return [...this.schemas.values()];
  }

  public freshPermissionInfo(permissions: Map<string, [[UserRole, UserRight]]>): void {
    for (const tableName of permissions.keys()) {
      const details = permissions.get(tableName);
      const schema = this.schemas.get(tableName);
      details?.forEach(([role, right]) => {
        schema?.setPermission(role, right);
      });
    }
  }

  public getDataModelHelper(): DataModelHelper {
    return this.dataModelHelper;
  }
}
