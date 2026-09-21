/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

import { Logger } from '@hw-agconnect/hmcore';
import { Utils } from '../utils/Utils';
import { DefaultNaturalStore } from './DefaultNaturalStore';
import { NaturalStore } from './NaturalStore';
import { CertificateService } from '../security/CertificateService';

import { ErrorCode } from '../utils/ErrorCode';
import { SecretKeyManager } from '../encrypt/SecretKeyManager';
import { ExceptionUtil } from '../utils/ExceptionUtil';
import { NaturalStoreObjectSchema } from './NaturalStoreObjectSchema';
import { SchemaUtils } from '../utils/SchemaUtils';
import { NaturalCloudStorage } from '../storage/NaturalCloudStorage';
import { EntireEncryption } from '../encrypt/EntireEncryption';
import { EntireEncryptInterval } from '../encrypt/EntireEncryptInterval';
import { NaturalBaseRef } from './NaturalBaseRef';
import { DataModelHelper } from './DataModelHelper';
import { ObjectTypeInfo } from '../Database';

const NATURAL_STORE_LIST_MAX_SIZE = 4;

const TAG = 'NaturalBase';

export type NaturalStoreResult = {
  naturalStore: NaturalStore | undefined;
  exceptionCode: ErrorCode;
};

export class NaturalBase implements NaturalBaseRef {
  public naturalStoreMap: Map<string, NaturalStore> = new Map();
  private defaultNStore: DefaultNaturalStore;
  private isUserKeyValid = false;
  private readonly cloudStorage: NaturalCloudStorage;
  private readonly secretKeyManager: SecretKeyManager;
  private readonly entireEncryptInterval: EntireEncryptInterval;
  private readonly certificateService: CertificateService;

  public constructor(region: string) {
    this.certificateService = new CertificateService(region);
    this.entireEncryptInterval = new EntireEncryptInterval();
    this.defaultNStore = new DefaultNaturalStore();
    this.cloudStorage = new NaturalCloudStorage(this);
    this.secretKeyManager = new SecretKeyManager(this);
  }

  getNaturalStore(storeName?: string): NaturalStore | undefined {
    if (Utils.isEmpty(storeName)) {
      return undefined;
    }
    return this.naturalStoreMap.get(storeName!);
  }

  getAllNaturalStore(): NaturalStore[] {
    return [...this.naturalStoreMap.values()];
  }

  public createObjectType(objectTypeInfo: ObjectTypeInfo): ErrorCode {
    this.validateSchemaInput(objectTypeInfo);
    const schemas = this.convert(objectTypeInfo);
    if (!this.defaultNStore) {
      Logger.error(TAG, `createObjectType: the default naturalStore is not inited.`);
      return ErrorCode.INTERNAL_ERROR;
    }
    if (this.naturalStoreMap.size !== 0) {
      Logger.warn(TAG, `createObjectType: opening naturalStore exists.`);
      return ErrorCode.CLOUDDBZONE_IS_OPENED;
    }

    const currentSchema = this.defaultNStore.getAppSchema();
    if (currentSchema.size !== 0) {
      const isEqualSchema = SchemaUtils.compareSchemas(
        this.defaultNStore.getAppVersion(),
        currentSchema,
        objectTypeInfo.schemaVersion,
        schemas
      );
      if (isEqualSchema) {
        return ErrorCode.OK;
      }
    }

    this.certificateService.setAppVersion(objectTypeInfo.schemaVersion);
    this.defaultNStore.createObjectType(objectTypeInfo.schemaVersion, schemas);
    return ErrorCode.OK;
  }

  public openNaturalStore(zoneName: string): NaturalStoreResult {
    const result: NaturalStoreResult = {
      naturalStore: undefined,
      exceptionCode: ErrorCode.INTERNAL_ERROR
    };
    if (this.defaultNStore instanceof DefaultNaturalStore) {
      if (!this.naturalStoreMap.has(zoneName)) {
        if (this.naturalStoreMap.size >= NATURAL_STORE_LIST_MAX_SIZE) {
          Logger.warn(TAG, `the count of natural store exceeds ${NATURAL_STORE_LIST_MAX_SIZE}`);
          result.exceptionCode = ErrorCode.CLOUDDBZONE_NUM_EXCEEDS_LIMIT;
          return result;
        }
        const naturalStore = new NaturalStore(zoneName, this);
        this.naturalStoreMap.set(naturalStore.naturalStoreId, naturalStore);
      }
      result.naturalStore = this.naturalStoreMap.get(zoneName);
      result.exceptionCode = ErrorCode.OK;
    }
    return result;
  }

  public async onConnect(): Promise<void> {
    Logger.debug(TAG, 'start onConnect');

    // const resultCode = await this.cloudStorage.onSubscribe(SubScribeRange.ALL_STORE,
    //   undefined, undefined, true);
    // if (resultCode !== ErrorCode.OK) {
    //   LOGGER.error(`Resubscribe fail for: ${resultCode}`);
    // }
    if (this.cloudStorage.needToDisconnectWebsocket() && !this.isUserKeyValid) {
      Logger.debug(TAG, 'need to disconnect');
      await this.cloudStorage.disconnectWebSocket();
    }
  }

  private validateSchemaInput(objectTypeInfo: ObjectTypeInfo): void {
    if (Utils.isNullOrUndefined(objectTypeInfo)) {
      throw ExceptionUtil.build(`The object type info must not be null.`);
    }
    if (
      Utils.isNullOrUndefined(objectTypeInfo.objectTypes) ||
      Utils.isNullOrUndefined(objectTypeInfo.permissions)
    ) {
      throw ExceptionUtil.build(`The object type list and permissions must not be null.`);
    }
    if (
      typeof objectTypeInfo.schemaVersion !== 'number' ||
      isNaN(objectTypeInfo.schemaVersion) ||
      objectTypeInfo.schemaVersion <= 0
    ) {
      throw ExceptionUtil.build(`The version of object type should be greater than 0.`);
    }
    if ((objectTypeInfo.objectTypes as []).length !== (objectTypeInfo.permissions as []).length) {
      throw ExceptionUtil.build(`The size of object type list should be the same as permissions.`);
    }
  }

  private convert(schema: ObjectTypeInfo): Map<string, NaturalStoreObjectSchema> {
    const permissions: any[] = schema.permissions;
    const objectTypes: any[] = schema.objectTypes;
    const schemas: Map<string, NaturalStoreObjectSchema> = new Map();
    const sortFn = (a: any, b: any) => {
      return a.objectTypeName === b.objectTypeName
        ? 0
        : a.objectTypeName > b.objectTypeName
        ? 1
        : -1;
    };
    if (permissions.length > 1) {
      permissions.sort(sortFn);
    }
    if (objectTypes.length > 1) {
      objectTypes.sort(sortFn);
    }
    for (let index = 0; index < permissions.length; index++) {
      const nsObjectSchema = new NaturalStoreObjectSchema(permissions[index], objectTypes[index]);
      SchemaUtils.validateObjectSchema(nsObjectSchema);
      schemas.set(nsObjectSchema.name, nsObjectSchema);
    }
    return schemas;
  }

  getDataModelHelper(): DataModelHelper {
    return this.defaultNStore?.getDataModelHelper();
  }

  getDefaultNaturalStore(): DefaultNaturalStore {
    return this.defaultNStore;
  }

  getEntireEncryptInterval(): EntireEncryptInterval {
    return this.entireEncryptInterval;
  }

  getEntireEncryption(): EntireEncryption {
    return this.secretKeyManager.getEntireEncryption();
  }

  getNaturalCloudStorage(): NaturalCloudStorage {
    return this.cloudStorage;
  }

  public getCertificateService(): CertificateService {
    return this.certificateService;
  }
}
