/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { DatabaseZoneSnapshot } from '../DatabaseZoneSnapshot';
import { DatabaseZoneSnapshotImpl } from '../impl/DatabaseZoneSnapshotImpl';
import { Utils } from '../utils/Utils';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { ErrorCode } from '../utils/ErrorCode';
import { FieldType } from '../utils/SchemaNamespace';
import { SchemaUtils } from '../utils/SchemaUtils';
import { NaturalBaseRef } from './NaturalBaseRef';
import { DataModelHelper } from './DataModelHelper';
import { NaturalCloudStorage } from '../storage/NaturalCloudStorage';
import { Condition, ConditionType, DatabaseZoneQuery } from '../DatabaseZoneQuery';
// @ts-ignore
import Long from 'long';

const TAG = 'NaturalStore';

const cannotInGroupConditionType = new Set([ConditionType.Limit, ConditionType.OrderBy]);

const NoFieldNameConditionTypes = new Set([
  ConditionType.Limit,
  ConditionType.Or,
  ConditionType.BeginGroup,
  ConditionType.EndGroup,
  ConditionType.And
]);

const predicateConditionType = new Set([
  ConditionType.BeginGroup,
  ConditionType.EndGroup,
  ConditionType.Or,
  ConditionType.And
]);

const NotSupportEncryptionConditionTypes = new Set([
  ConditionType.In,
  ConditionType.Average,
  ConditionType.Contains,
  ConditionType.BeginsWith,
  ConditionType.EndsWith
]);

const EncryptionConditionTypes = new Set([
  ConditionType.EqualTo,
  ConditionType.NotEqualTo,
  ConditionType.GreaterThan,
  ConditionType.GreaterThanOrEqualTo,
  ConditionType.LessThan,
  ConditionType.LessThanOrEqualTo
]);

const NoValueConditionType = new Set(['IsNull', 'IsNotNull', 'OrderBy', 'Count']);

const OPE_STRING = '#ope';
const MAX_CONDITION_COUNT = 30;

export class NaturalStore {
  readonly naturalStoreId: string;
  readonly references = new Set<string>();
  private readonly cloudStorage: NaturalCloudStorage;
  private readonly naturalBaseRef: NaturalBaseRef;

  constructor(naturalStoreId: string, naturalBaseRef: NaturalBaseRef) {
    this.naturalStoreId = naturalStoreId;
    this.cloudStorage = naturalBaseRef.getNaturalCloudStorage();
    this.naturalBaseRef = naturalBaseRef;
  }

  getNaturalStoreName() {
    return this.naturalStoreId;
  }

  public async executeUpsert(objects: any[]): Promise<number> {
    const upsertObjects = await this.naturalBaseRef
      .getEntireEncryption()
      .encryptEntireEncryptedFields(objects);
    return await this.cloudStorage.executeUpsert(upsertObjects, this.naturalStoreId);
  }

  public async executeDelete(objects: any[]): Promise<number> {
    await this.naturalBaseRef
      .getEntireEncryption()
      .isValidEncryptionOperation(Utils.getClassName(objects[0]));
    return await this.cloudStorage.executeDelete(objects, this.naturalStoreId);
  }

  public async executeQuery<T>(query: DatabaseZoneQuery<T>): Promise<DatabaseZoneSnapshot<T>> {
    this.checkQueryClass(query);
    await this.naturalBaseRef
      .getEntireEncryption()
      .isValidEncryptionOperation(query.getClassName());
    const queryCondition = await this.getQueryConditionByString(
      query.getClassName(),
      query.getQueryConditions()
    );
    const objects = await this.cloudStorage.executeQuery(
      this.naturalStoreId,
      query.getClassName(),
      queryCondition
    );
    const decryptObjects = await this.naturalBaseRef
      .getEntireEncryption()
      .decryptEntireEncryptedFields(query, objects);
    return new DatabaseZoneSnapshotImpl(decryptObjects, [], []);
  }

  async getQueryConditionByString(
    schemaName: string,
    queryConditions: Condition[]
  ): Promise<string> {
    const conditions: Condition[] = [];
    for (const condition of queryConditions) {
      if (condition.conditionType === ConditionType.And) {
        continue;
      }
      if (this.isInvalidCondition(condition)) {
        Logger.error(TAG, `getQueryConditionByString fail for invalid query condition!`);
        throw ExceptionUtil.build(`Invalid query conditions.`);
      }
      const item: Condition = {
        fieldName: condition.fieldName,
        conditionType: condition.conditionType,
        value: undefined
      };
      const fieldInfo = this.naturalBaseRef
        .getDataModelHelper()
        .getFieldInfoByName(schemaName, condition.fieldName!);
      if (!fieldInfo && !NoFieldNameConditionTypes.has(condition.conditionType as any)) {
        throw ExceptionUtil.build('The field name does not exist.');
      }
      if (!fieldInfo?.isEncryptField) {
        item.fieldType = fieldInfo?.fieldType;
        if (condition.value instanceof Date) {
          item.value = condition.value.getTime();
        } else if (condition.value instanceof Long) {
          item.value = condition.value.toString();
        } else if (Utils.isArray(condition.value)) {
          item.value = this.arrayToString(condition.value);
        } else {
          item.value = condition.value;
        }
        conditions.push(item);
        continue;
      }
      const conditionType = condition.conditionType as ConditionType;
      if (NotSupportEncryptionConditionTypes.has(conditionType)) {
        throw ExceptionUtil.build(`Encrypted field does not support ${conditionType}.`);
      }
      item.fieldName = condition.fieldName + OPE_STRING;
      item.fieldType = FieldType.String;
      if (EncryptionConditionTypes.has(conditionType)) {
        item.value = await this.naturalBaseRef
          .getEntireEncryption()
          .conditionEntireEncryptedField(
            schemaName,
            condition.fieldName!,
            fieldInfo.fieldType,
            condition.value
          );
      } else {
        item.value = condition.value;
      }
      conditions.push(item);
    }
    return JSON.stringify({ queryConditions: conditions });
  }

  private arrayToString(values: any): unknown[] {
    const candidates: unknown[] = [];
    for (const item of values) {
      let value = item;
      if (item instanceof Date) {
        value = item.getTime();
      } else if (item instanceof Long) {
        value = item.toString();
      }
      candidates.push(value);
    }
    return candidates;
  }

  private isInvalidCondition(condition: Condition): boolean {
    return (
      !condition.conditionType ||
      (!NoFieldNameConditionTypes.has(condition.conditionType as any) && !condition.fieldName)
    );
  }

  public checkQueryClass<T>(databaseZoneQuery: DatabaseZoneQuery<T>) {
    if (Utils.isNullOrUndefined(databaseZoneQuery)) {
      throw ExceptionUtil.build('DatabaseZoneQuery must not be null.');
    }
    if (!(databaseZoneQuery instanceof DatabaseZoneQuery)) {
      throw ExceptionUtil.build('The type of input must be DatabaseZoneQuery.');
    }
    const clazz = databaseZoneQuery.getClazz();
    if (typeof clazz !== 'function') {
      throw ExceptionUtil.build('The input parameter is not a class.');
    }
    if (!databaseZoneQuery.getQueryConditions()) {
      Logger.warn(TAG, 'checkSubscribeQuery: failed to get conditions array.');
      throw ExceptionUtil.build('Invalid query conditions.');
    }
    const fieldNames = Object.getOwnPropertyNames(new clazz());
    if (
      Utils.isEmpty(databaseZoneQuery.getClassName()) ||
      !this.naturalBaseRef.getDataModelHelper().validate(new clazz())
    ) {
      throw ExceptionUtil.build(ErrorCode.OBJECT_TYPE_NO_EXIST);
    }
    const fieldInfos = this.naturalBaseRef
      .getDataModelHelper()
      .getFieldInfosByClassName(databaseZoneQuery.getClassName());
    if (fieldNames.length !== fieldInfos?.size) {
      throw ExceptionUtil.build(
        'The field size of input object is different with that of the imported class.'
      );
    }
    for (const name of fieldNames) {
      if (!fieldInfos.has(name)) {
        throw ExceptionUtil.build('The field does not exist.');
      }
    }
    this.checkConditions(databaseZoneQuery);
  }

  private checkConditions<T>(databaseZoneQuery: DatabaseZoneQuery<T>) {
    if (databaseZoneQuery.getDepth() !== 0) {
      throw ExceptionUtil.build(
        'The query beginGroup and endGroup ' + 'should come in pairs with right direction.'
      );
    }
    const length = databaseZoneQuery.getQueryConditions().length;
    if (length > MAX_CONDITION_COUNT) {
      throw ExceptionUtil.build('Query type exceeds the limit.');
    }
    let depth = 0;
    const className = databaseZoneQuery.getClassName();
    const conditions = databaseZoneQuery.getQueryConditions();
    for (let i = 0; i < length; i++) {
      const condition = conditions[i];
      if (predicateConditionType.has(condition.conditionType as any)) {
        depth = this.validBeginOrEndGroup(condition, conditions, i, depth);
        this.validOrAndCondition(condition, conditions, i);
      }
      if (
        cannotInGroupConditionType.has(condition.conditionType as any) &&
        (depth !== 0 ||
          (i !== 0 &&
            (conditions[i - 1].conditionType === ConditionType.And ||
              conditions[i - 1].conditionType === ConditionType.Or)))
      ) {
        if (condition.conditionType === ConditionType.OrderBy) {
          throw ExceptionUtil.build(`near "${condition.value}": syntax error.`);
        }
        throw ExceptionUtil.build(`near "${condition.conditionType}": syntax error.`);
      }
      if (NoFieldNameConditionTypes.has(condition.conditionType as any)) {
        continue;
      }
      Utils.checkNotNull(condition.fieldName, `The field name must not be null.`);
      const fieldInfo = this.naturalBaseRef
        .getDataModelHelper()
        .getFieldInfoByName(className, condition.fieldName!);
      if (!fieldInfo) {
        throw ExceptionUtil.build(`The field name does not exist.`);
      }
      if (NoValueConditionType.has(condition.conditionType)) {
        continue;
      }
      if (!this.checkConditionTypeAndFieldType(condition.conditionType, fieldInfo.fieldType)) {
        throw ExceptionUtil.build(
          `The ${FieldType[fieldInfo.fieldType]} type does not support the ${
            condition.conditionType
          } operation.`
        );
      }
      const values = Utils.convertArray(condition.value);
      for (const value of values) {
        SchemaUtils.validateFieldValueForQuery(fieldInfo.fieldType, value);
      }
    }
  }

  private checkConditionTypeAndFieldType(
    conditionType: ConditionType,
    fieldType: FieldType
  ): boolean {
    switch (conditionType) {
      case ConditionType.EqualTo:
      case ConditionType.NotEqualTo:
        return fieldType !== FieldType.ByteArray;
      case ConditionType.GreaterThan:
      case ConditionType.GreaterThanOrEqualTo:
      case ConditionType.LessThan:
      case ConditionType.LessThanOrEqualTo:
      case ConditionType.In:
        return fieldType !== FieldType.Boolean && fieldType !== FieldType.ByteArray;
      case ConditionType.BeginsWith:
      case ConditionType.EndsWith:
      case ConditionType.Contains:
        return fieldType === FieldType.Text || fieldType === FieldType.String;
      default:
        return false;
    }
  }

  public getDataModelHelper(): DataModelHelper {
    return this.naturalBaseRef.getDataModelHelper();
  }

  private validOrAndCondition(condition: Condition, conditions: Condition[], index: number) {
    if (
      condition.conditionType === ConditionType.Or ||
      condition.conditionType === ConditionType.And
    ) {
      if (
        index === 0 ||
        index === conditions.length - 1 ||
        conditions[index - 1].conditionType === ConditionType.BeginGroup ||
        conditions[index - 1].conditionType === ConditionType.Or ||
        conditions[index - 1].conditionType === ConditionType.And
      ) {
        throw ExceptionUtil.build(`near "${condition.conditionType}": syntax error.`);
      }
    }
  }

  private validBeginOrEndGroup(
    condition: Condition,
    conditions: Condition[],
    index: number,
    depth: number
  ) {
    if (condition.conditionType === ConditionType.BeginGroup) {
      depth++;
    }
    if (condition.conditionType === ConditionType.EndGroup) {
      depth--;
      if (depth < 0) {
        throw ExceptionUtil.build(
          'The query beginGroup and endGroup ' + 'should come in pairs with right direction.'
        );
      }
      const preConditionType = conditions[index - 1].conditionType;
      if (
        preConditionType === ConditionType.BeginGroup ||
        preConditionType === ConditionType.Or ||
        preConditionType === ConditionType.And
      ) {
        throw ExceptionUtil.build(`near "${condition.conditionType}": syntax error.`);
      }
    }
    return depth;
  }
}
