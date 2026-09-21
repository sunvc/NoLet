/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { ObjectWrapper } from '../sync/ObjectWrapper';

export type PrimaryKeyType = string | number;

export type SubSignature = number;

const SIGNATURE_JOINER = '-';
const UNLIMITED_CACHE_CAPACITY = -1;

abstract class Cache<T> {
  protected primaryKeys: string[];
  protected capacity_: number = UNLIMITED_CACHE_CAPACITY;
  protected cacheNodeMap: Map<number, T> = new Map();

  constructor(primaryKeys: string[]) {
    this.primaryKeys = primaryKeys;
  }

  public get capacity() {
    return this.capacity_;
  }

  abstract cache(record: object, versionId?: number, reference?: SubSignature): T;

  abstract remove(versionId: number, reference: SubSignature): void;

  abstract get(versionId: number): T | undefined;

  protected hash(value: string | number) {
    const str = '' + value;
    let hash = 5381;
    let index = str.length;
    while (index) {
      hash = (hash * 33) ^ str.charCodeAt(--index);
    }
    return '' + (hash >>> 0);
  }

  public getRecordHash(record: unknown): string {
    let value = 'R';
    this.primaryKeys.forEach((key: string) => {
      value = value + SIGNATURE_JOINER + (record as any)[key];
    });
    return this.hash(value);
  }
}

export class CacheNode<T> {
  public readonly versionId: number;
  public keys?: PrimaryKeyType[];
  public record?: T;

  constructor(versionId: number) {
    this.versionId = versionId;
  }
}

export class SnapshotCache extends Cache<CacheNode<ObjectWrapper>> {
  constructor(primaryKeys: string[]) {
    super(primaryKeys);
    this.capacity_ = UNLIMITED_CACHE_CAPACITY;
  }

  public cache(record: ObjectWrapper, versionId: number): CacheNode<ObjectWrapper> {
    let node = this.cacheNodeMap.get(versionId);
    if (!node) {
      node = new CacheNode(versionId);
      this.cacheNodeMap.set(versionId, node);
    }
    node.record = record;
    return node;
  }

  public remove(versionId: number): void {
    if (!versionId) {
      return undefined;
    }
    const node = this.cacheNodeMap.get(versionId);
    if (node) {
      this.cacheNodeMap.delete(versionId);
    }
  }

  public get(versionId: number): CacheNode<ObjectWrapper> | undefined {
    if (!versionId) {
      return undefined;
    }
    return this.cacheNodeMap.get(versionId);
  }
}
