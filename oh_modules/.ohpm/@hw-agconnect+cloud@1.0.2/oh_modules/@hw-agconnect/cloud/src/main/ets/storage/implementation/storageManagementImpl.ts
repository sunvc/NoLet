import { StorageReferenceImpl } from './storageReferenceImpl';
import { Location } from './location';
import { CloudStorageRequest } from '../server/request/CloudStorageRequest';
import { CloudStorageConfig } from '../utils/CloudStorageConfig';
import * as Validator from '../utils/validator';

import * as constants from './constants';
import { CloudStorageBackend } from '../server/backend/CloudStorageBackend';
import { StorageManagement, StorageReference } from '../interface/innerInterface';
import { AGCStorageError, AGCStorageErrorCode } from './error';

export class StorageManagementImpl implements StorageManagement {
  public readonly region: string;
  private _bucket: Location | string = '';
  private _config: CloudStorageConfig;
  private _maxRequestTimeout: number;
  private _maxUploadTimeout: number;
  private _maxRetryTimes: number;
  private _bucketName: string | undefined;
  private readonly _cloudStorageBackend: CloudStorageBackend;
  private _ignoreRetryWaiting: boolean = false;

  constructor(region: string, bucket: string) {
    this._maxRequestTimeout = constants.DEFAULT_MAX_REQUEST_TIMEOUT;
    this._maxUploadTimeout = constants.DEFAULT_MAX_UPLOAD_TIMEOUT;
    this._maxRetryTimes = constants.DEFAULT_MAX_RETRY_TIMES;

    this.region = region;
    this._bucketName = bucket;
    this._config = CloudStorageConfig.initInstance(this.region);
    this._cloudStorageBackend = new CloudStorageBackend();
  }

  private async init() {
    await this._config.init();
    if (this._bucketName) {
      this._bucket = Location.makeFromBucket(this._bucketName);
    } else if (this._config.defaultBucket() == '') {
      throw new AGCStorageError(AGCStorageErrorCode.INVALID_CONFIG);
    } else {
      this._bucket = Location.makeFromBucket(this._config.defaultBucket());
    }
  }

  async storageReference(path?: string): Promise<StorageReference> {
    StorageManagementImpl.validatePath(path);
    await this.init();
    if (this._bucket === null) {
      throw new AGCStorageError(AGCStorageErrorCode.NO_DEFAULT_BUCKET);
    }

    const ref: StorageReference = new StorageReferenceImpl(this, this.region, this._bucket);
    if (path) {
      return ref.child(path);
    }
    return ref;
  }

  private static validatePath(path?: string) {
    Validator.validate(
      'storagemanagement.storageReference',
      [Validator.stringSpec(Validator.forbiddenSymbol, true)],
      arguments
    );
  }

  maxUploadTimeout(): number {
    return this._maxUploadTimeout;
  }

  maxRequestTimeout(): number {
    return this._maxRequestTimeout;
  }

  maxRetryTimes(): number {
    return this._maxRetryTimes;
  }

  setMaxRetryTimes(value: number) {
    Validator.validate(
      'storageManagement.setMaxRetryTimes',
      [Validator.nonNegativeNumberSpec()],
      arguments
    );
    this._maxRetryTimes = value;
  }

  setIgnoreRetryWaiting(value: boolean) {
    this._ignoreRetryWaiting = value;
  }

  ignoreRetryWaiting(): boolean {
    return this._ignoreRetryWaiting;
  }

  makeStorageReference(location: Location, area: string): StorageReference {
    return new StorageReferenceImpl(this, area, location);
  }

  makeRequest(
    requestInfo: CloudStorageRequest<any>,
    retryTimes: number = 1,
    lastUrl?: string
  ): Promise<any> {
    return this._cloudStorageBackend.makeRequest(requestInfo, retryTimes, lastUrl);
  }
}
