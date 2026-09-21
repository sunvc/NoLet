/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2021. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { NaturalStore } from './base/NaturalStore';
import { DatabaseZoneQuery } from './DatabaseZoneQuery';

import { Utils } from './utils/Utils';
import { ExceptionUtil } from './utils/ExceptionUtil';

const MAX_OBJECT_LIST_SIZE = 1000;
const MAX_OBJECT_LIST_CAPACITY = 2 * 1024 * 1024;
const TAG = 'DatabaseCollection';

/**
 * CloudDBZone object interface.
 *
 * @since 2020-09-15
 */
export class DatabaseCollection<T> {
  private naturalStore: NaturalStore;
  private readonly clazz: (new () => T) | undefined;

  /**
   *
   * @param clazz clazz
   * @param naturalStore natural store instance
   */
  constructor(naturalStore: NaturalStore, clazz?: new () => T) {
    this.naturalStore = naturalStore;
    this.clazz = clazz;
  }

  public query(): DatabaseZoneQuery<T> {
    return new DatabaseZoneQuery(this.naturalStore, this.clazz);
  }

  /**
   * developers use this API to insert/update specific records in a table.
   *
   * @param objectList single object/object list need to be insert/updated to database.
   * @returns promise with number.
   */
  public async upsert<T>(objectList: T[] | T): Promise<number> {
    const objects = this.convert(objectList);
    if (objects.length === 0) {
      Logger.warn(TAG, 'ObjectList is empty when executeUpsert.');
      return Promise.resolve(0);
    }
    return this.executeUpsert(objects);
  }

  /**
   * developers use this API to delete specific records in a table.
   *
   * @param objectList single object/object list need to be deleted from database.
   * @returns promise with number.
   */
  public async delete<T>(objectList: T[] | T): Promise<number> {
    const objects = this.convert(objectList);
    if (objects.length === 0) {
      Logger.warn(TAG, 'ObjectList is empty when executeUpsert.');
      return Promise.resolve(0);
    }
    return this.executeDelete(objects);
  }

  private convert<T>(objectList: T[] | T): T[] {
    const list: any[] = [];
    const objects = Utils.convertArray(objectList);

    for (const object of objects) {
      const objectData: any = this.naturalStore
        .getDataModelHelper()
        .deserialize(this.clazz!, object as unknown as object);
      list.push(objectData);
    }
    return list;
  }

  private async executeUpsert<T>(objectList: T[]): Promise<number> {
    this.isValidOperation(objectList);

    this.validateObjectList(objectList);
    return new Promise((resolve, reject) => {
      this.naturalStore
        .executeUpsert(objectList)
        .then(upsertNum => {
          resolve(upsertNum);
        })
        .catch(error => {
          reject(Utils.isErrorObject(error) ? error : ExceptionUtil.build(error));
        });
    });
  }

  private validateObjectType<T>(objects: T[]): boolean {
    for (const item of objects) {
      if (!this.naturalStore.getDataModelHelper().validate(item)) {
        return false;
      }
    }
    return true;
  }

  private calculateObjectListSize<T>(objects: T[]): number {
    let objectListSize = 0;
    objects.forEach(item => {
      objectListSize += this.naturalStore.getDataModelHelper().calculateObject(item);
    });
    return objectListSize;
  }

  private async executeDelete<T>(objectList: T[]): Promise<number> {
    this.isValidOperation(objectList);

    this.validateObjectList(objectList);
    return new Promise((resolve, reject) => {
      this.naturalStore
        .executeDelete(objectList)
        .then(delNum => {
          resolve(delNum);
        })
        .catch(error => {
          reject(Utils.isErrorObject(error) ? error : ExceptionUtil.build(error));
        });
    });
  }

  private validateObjectList<T>(objects: T[]) {
    if (objects.length > MAX_OBJECT_LIST_SIZE) {
      throw ExceptionUtil.build(`The size of object list exceeds the limit.`);
    }
    if (!Utils.isSameObjectType(objects)) {
      throw ExceptionUtil.build(`Only one object type is supported for batch operations.`);
    }
    if (!this.validateObjectType(objects)) {
      throw ExceptionUtil.build(`The object type is not loaded yet.`);
    }
    if (this.calculateObjectListSize(objects) > MAX_OBJECT_LIST_CAPACITY) {
      throw ExceptionUtil.build(`The capacity of objects exceeds the limit.`);
    }
  }

  private checkCloudDBZoneHandle() {
    if (!this.naturalStore) {
      Logger.warn(TAG, 'The CloudDBZone has not been created or opened.');
      throw ExceptionUtil.build('The CloudDBZone has not been created or opened.');
    }
  }

  private isValidOperation(objectList: any) {
    this.checkCloudDBZoneHandle();
    if (!Utils.isValidObject(objectList)) {
      throw ExceptionUtil.build(`The object list is invalid.`);
    }
  }
}
