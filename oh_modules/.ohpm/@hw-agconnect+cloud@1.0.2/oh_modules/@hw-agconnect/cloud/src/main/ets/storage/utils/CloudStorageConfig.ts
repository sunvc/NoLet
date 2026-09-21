/**
 * @fileOverview this class is used to get agcconnect configuration
 */
import { getString } from '@hw-agconnect/hmcore';
import { AGCStorageError, AGCStorageErrorCode } from '../implementation/error';

export class CloudStorageConfig {
  private static instance: CloudStorageConfig;
  private _storageHosts: StorageConfig = {};
  private _defaultBucket: string = '';
  private _defaultRegion: string = '';
  private _addressThreshold: number = 3;

  constructor(region: string) {
    this._defaultRegion = region;
  }

  async init() {
    let storageConf: StorageConfig = getString('/service/cloudstorage') as StorageConfig;
    this.generateUrl(storageConf);
    this._defaultBucket = storageConf.default_storage ? storageConf.default_storage : '';
  }

  public static initInstance(region: string): CloudStorageConfig {
    this.instance = new CloudStorageConfig(region);
    return this.instance;
  }

  public static getInstance(): CloudStorageConfig {
    return this.instance;
  }

  getHostByRegion(region: string): AddressCount {
    region = region ? region : this._defaultRegion;
    let reginKey = 'storage_url_' + region.toLowerCase();
    let temp = this._storageHosts[reginKey];
    let i = 0;
    for (; i < 2; i++) {
      let info = temp[String(i)] as AddressCount;
      if (!info) {
        throw new AGCStorageError(AGCStorageErrorCode.INVALID_ADDRESS);
      }
      if (info.count < this._addressThreshold) {
        return info;
      } else if (i === 1) {
        return info;
      }
    }
    throw new AGCStorageError(AGCStorageErrorCode.INVALID_ADDRESS);
  }

  clearHostCount(region: string, index: number) {
    let reginKey = 'storage_url_' + region.toLowerCase();
    let temp = this._storageHosts[reginKey];
    temp[index].count = 0;
    this._storageHosts[reginKey] = temp;
  }

  setHostCount(region: string, index: number) {
    if (index === 1) {
      return;
    }
    let reginKey = 'storage_url_' + region.toLowerCase();
    let temp = this._storageHosts[reginKey];
    temp[index].count += 1;
    this._storageHosts[reginKey] = temp;
  }

  defaultBucket(): string {
    return this._defaultBucket;
  }

  defaultRegion(): string {
    return this._defaultRegion;
  }

  private generateUrl(storage: StorageConfig): void {
    const regions = ['storage_url_cn', 'storage_url_sg', 'storage_url_ru', 'storage_url_de'];
    for (let region of regions) {
      let temp = {};
      for (let key in storage) {
        if (key === region) {
          temp = Object.assign(
            {
              '0': {
                url: storage[key],
                index: 0,
                count: 0
              } as AddressCount
            },
            temp
          );
        } else if (key.indexOf(region) !== -1) {
          temp = Object.assign(
            {
              '1': {
                url: storage[key],
                index: 1,
                count: 0
              } as AddressCount
            },
            temp
          );
        }
      }
      this._storageHosts[region] = temp;
    }
  }
}

export interface AddressCount {
  url: string;
  index: number;
  count: number;
}

interface StorageConfig {
  [key: string]: any;
}
