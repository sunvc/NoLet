/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { FieldType } from './utils/SchemaNamespace';
import { Utils } from './utils/Utils';
import { ExceptionUtil } from './utils/ExceptionUtil';
import { NaturalStore } from './base/NaturalStore';

export type Condition = {
  conditionType: ConditionType;
  fieldName: string | undefined;
  value: unknown;
  fieldType?: FieldType;
};

export const enum ConditionType {
  BeginsWith = 'BeginWith',
  EndsWith = 'EndWith',
  Contains = 'Contain',
  EqualTo = 'EqualTo',
  NotEqualTo = 'NotEqualTo',
  GreaterThan = 'GreaterThan',
  GreaterThanOrEqualTo = 'GreaterThanOrEqualTo',
  LessThan = 'LessThan',
  LessThanOrEqualTo = 'LessThanOrEqualTo',
  In = 'In',
  Average = 'Average',
  IsNull = 'IsNull',
  IsNotNull = 'IsNotNull',
  OrderBy = 'OrderBy',
  Limit = 'Limit',
  Or = 'Or',
  And = 'And',
  BeginGroup = 'BeginGroup',
  EndGroup = 'EndGroup'
}

const enum OrderType {
  Ascend = 'ASC',
  Descend = 'DESC'
}

const cannotInGroupConditionType = new Set([ConditionType.Limit, ConditionType.OrderBy]);

const MAX_CONDITION_COUNT = 30;

/**
 * DatabaseZoneQuery describe how to select objects from cloudDBZone.
 *
 * @since 2020-09-15
 */
export class DatabaseZoneQuery<T> {
  private readonly queryConditions: Condition[];
  private readonly clazz: (new () => T) | undefined;
  private depth: number;
  private naturalStore: NaturalStore;

  public constructor(naturalStore: NaturalStore, clazz?: new () => T) {
    this.clazz = clazz;
    this.queryConditions = [];
    this.depth = 0;
    this.naturalStore = naturalStore;
  }

  private addCondition(
    conditionType: ConditionType,
    fieldName: string | undefined,
    value?: any | any[]
  ) {
    if (this.queryConditions.length >= MAX_CONDITION_COUNT) {
      throw ExceptionUtil.build('Query type exceeds the limit.');
    }
    const conditionObject: Condition = { conditionType, fieldName, value };
    this.queryConditions.push(conditionObject);
    return this;
  }

  /**
   * Add equal to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public equalTo(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.EqualTo, fieldName, value);
  }

  /**
   * Add beginWith to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public beginsWith(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.BeginsWith, fieldName, value);
  }

  /**
   * Add endsWith to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public endsWith(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.EndsWith, fieldName, value);
  }

  /**
   * Add contains to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public contains(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.Contains, fieldName, value);
  }

  /**
   * Add not equal to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public notEqualTo(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.NotEqualTo, fieldName, value);
  }

  /**
   * Add greater than condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public greaterThan(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.GreaterThan, fieldName, value);
  }

  /**
   * Add greater than or equal to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public greaterThanOrEqualTo(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.GreaterThanOrEqualTo, fieldName, value);
  }

  /**
   * Add less than to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public lessThan(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.LessThan, fieldName, value);
  }

  /**
   * Add less than or equal to condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @param value The value of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public lessThanOrEqualTo(fieldName: string, value: any) {
    this.checkFieldValidity(fieldName, value);
    return this.addCondition(ConditionType.LessThanOrEqualTo, fieldName, value);
  }

  /**
   * Add in condition for array.
   *
   * @param fieldName The name of the field used for being compared.
   * @param values The value array of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public In(fieldName: string, values: any[]) {
    if (!Utils.isArray(values)) {
      throw ExceptionUtil.build(`The values must be array.`);
    }
    this.checkFieldValidity(fieldName, ...values);
    return this.addCondition(ConditionType.In, fieldName, values);
  }

  /**
   * Add isNull condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public isNull(fieldName: string) {
    this.checkFieldValidity(fieldName);
    return this.addCondition(ConditionType.IsNull, fieldName);
  }

  /**
   * Add isNotNull condition for value.
   *
   * @param fieldName The name of the field used for being compared.
   * @returns DatabaseZoneQuery itself.
   */
  public isNotNull(fieldName: string) {
    this.checkFieldValidity(fieldName);
    return this.addCondition(ConditionType.IsNotNull, fieldName);
  }

  /**
   * Add order by asc condition.
   *
   * @param fieldName The name of the field used for order.
   * @returns DatabaseZoneQuery itself.
   */
  public orderByAsc(fieldName: string) {
    this.checkFieldValidity(fieldName);
    this.isValidCloudDBQuery(ConditionType.OrderBy, OrderType.Ascend);
    return this.addCondition(ConditionType.OrderBy, fieldName, OrderType.Ascend);
  }

  /**
   * Add order by desc condition.
   *
   * @param fieldName The name of the field used for order.
   * @returns DatabaseZoneQuery itself.
   */
  public orderByDesc(fieldName: string) {
    this.checkFieldValidity(fieldName);
    this.isValidCloudDBQuery(ConditionType.OrderBy, OrderType.Descend);
    return this.addCondition(ConditionType.OrderBy, fieldName, OrderType.Descend);
  }

  /**
   * Add limit condition.
   *
   * @param count the limit number.
   * @param offset the offset number, this parameter is optional.
   * @returns DatabaseZoneQuery itself.
   */
  public limit(count: number, offset?: number) {
    if (typeof count !== 'number' || Math.floor(count) !== count || count <= 0) {
      throw ExceptionUtil.build('The Count is invalid.');
    }
    if (Utils.isNullOrUndefined(offset)) {
      offset = 0;
    }
    if (typeof offset !== 'number' || Math.floor(offset) !== offset || offset < 0) {
      throw ExceptionUtil.build('The Offset is invalid.');
    }
    this.isValidCloudDBQuery(ConditionType.Limit);
    return this.addCondition(ConditionType.Limit, undefined, {
      offset: offset !== void 0 ? offset : 0,
      number: count
    });
  }

  /**
   * Add beginGroup condition.
   *
   * @returns DatabaseZoneQuery itself.
   */
  public beginGroup() {
    this.isValidCloudDBQuery(ConditionType.BeginGroup);
    this.depth++;
    return this.addCondition(ConditionType.BeginGroup, undefined);
  }

  /**
   * Add endGroup condition.
   *
   * @returns DatabaseZoneQuery itself.
   */
  public endGroup() {
    this.isValidCloudDBQuery(ConditionType.EndGroup);
    this.depth--;
    return this.addCondition(ConditionType.EndGroup, undefined);
  }

  /**
   * Add or condition.
   *
   * @returns DatabaseZoneQuery itself.
   */
  public or() {
    this.isValidCloudDBQuery(ConditionType.Or);
    return this.addCondition(ConditionType.Or, undefined);
  }

  /**
   * Add and condition.
   *
   * @returns DatabaseZoneQuery itself.
   */
  public and() {
    this.isValidCloudDBQuery(ConditionType.And);
    return this.addCondition(ConditionType.And, undefined);
  }

  public async get(): Promise<T[]> {
    let result = await this.naturalStore.executeQuery(this);
    return result.getSnapshotObjects();
  }

  getClassName(): string {
    const className = (this.clazz as any).className;
    return className ? className : this.clazz?.name;
  }

  getClazz() {
    return this.clazz;
  }

  getQueryConditions() {
    return this.queryConditions;
  }

  getDepth() {
    return this.depth;
  }

  private checkFieldValidity(fieldName: string, ...values: unknown[]) {
    Utils.checkNotNull(fieldName, `The field name must not be null.`);
    for (const value of values) {
      Utils.checkNotNull(value, 'The value is invalid.');
    }
  }

  private isValidCloudDBQuery(conditionType: ConditionType, orderType?: OrderType) {
    const length = this.queryConditions.length;
    const lastConditionType = length === 0 ? null : this.queryConditions[length - 1].conditionType;
    // limit or order by is not
    if (cannotInGroupConditionType.has(conditionType)) {
      if (
        this.depth !== 0 ||
        lastConditionType === ConditionType.Or ||
        lastConditionType === ConditionType.And
      ) {
        if (conditionType === ConditionType.OrderBy) {
          throw ExceptionUtil.build(`near "${orderType}": syntax error.`);
        }
        throw ExceptionUtil.build(`near "${conditionType}": syntax error.`);
      }
    }
    if (conditionType === ConditionType.Or || conditionType === ConditionType.And) {
      if (
        length === 0 ||
        lastConditionType === ConditionType.BeginGroup ||
        cannotInGroupConditionType.has(lastConditionType as any) ||
        lastConditionType === ConditionType.Or ||
        lastConditionType === ConditionType.And
      ) {
        throw ExceptionUtil.build(`near "${conditionType}": syntax error.`);
      }
    }
    if (conditionType === ConditionType.EndGroup) {
      if (this.depth <= 0) {
        throw ExceptionUtil.build(
          'The query beginGroup and endGroup ' + 'should come in pairs with right direction.'
        );
      }
      if (
        length === 0 ||
        lastConditionType === ConditionType.BeginGroup ||
        lastConditionType === ConditionType.Or ||
        lastConditionType === ConditionType.And
      ) {
        throw ExceptionUtil.build(`near "${conditionType}": syntax error.`);
      }
    }
  }
}
