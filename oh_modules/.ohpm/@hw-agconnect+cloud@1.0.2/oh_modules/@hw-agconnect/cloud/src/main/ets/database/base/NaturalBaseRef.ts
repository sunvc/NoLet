/**
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */
import { DataModelHelper } from './DataModelHelper';
import { EntireEncryption } from '../encrypt/EntireEncryption';
import { DefaultNaturalStore } from './DefaultNaturalStore';
import { EntireEncryptInterval } from '../encrypt/EntireEncryptInterval';
import { NaturalStore } from './NaturalStore';
import { NaturalCloudStorage } from '../storage/NaturalCloudStorage';
import { CertificateService } from '../security/CertificateService';

export interface NaturalBaseRef {
  getDataModelHelper(): DataModelHelper;

  getEntireEncryption(): EntireEncryption;

  getDefaultNaturalStore(): DefaultNaturalStore;

  getEntireEncryptInterval(): EntireEncryptInterval;

  getNaturalStore(storeName?: string): NaturalStore | undefined;

  getAllNaturalStore(): NaturalStore[];

  getNaturalCloudStorage(): NaturalCloudStorage;

  onConnect(): Promise<void>;

  getCertificateService(): CertificateService;
}
