import { CSBlob } from '../upload/file';
import { Location } from './location';
import * as path from './path';
import { UploadTaskImpl } from '../upload/task';
import { StorageManagementImpl } from './storageManagementImpl';
import { forbiddenSymbol, metadataSpec, pathLengthSpec, uploadDataSpec, validate } from '../utils/validator';
import { ListRequest } from '../server/request/ListRequest';
import { DeleteRequest } from '../server/request/DeleteRequest';
import { GetDownloadUrlRequest } from '../server/request/GetDownloadUrlRequest';
import { ListOptions, ListRefResult, StorageManagement, StorageReference } from '../interface/innerInterface';
import { GetFileMetadataRequest } from '../server/request/GetFileMetadataRequest';
import { MetadataComplete, ProgressEvent, TransResult } from '../storage';
import { UpdateFileMetaDataRequest } from '../server/request/UpdateFileMetaDataRequest';
import request from '@ohos.request';
import { getContext } from '@hw-agconnect/hmcore';
import { AGCStorageError, AGCStorageErrorCode } from './error';
import url from '@ohos.url';

export class StorageReferenceImpl implements StorageReference {
  protected location: Location;
  private _area: string;

  constructor(
    protected storageManagement: StorageManagementImpl,
    area: string,
    location: string | Location
  ) {
    this._area = area;
    if (location instanceof Location) {
      this.location = location;
    } else {
      this.location = Location.makeFromUrl(location);
    }
  }

  parent(): StorageReference | null {
    const newPath = path.parent(this.location.path());
    if (newPath === null) {
      return null;
    }
    const location = new Location(this.location.bucket, newPath);
    return this.newRef(this.storageManagement, this._area, location);
  }

  root(): StorageReference {
    const location = new Location(this.location.bucket, '');
    return this.newRef(this.storageManagement, this._area, location);
  }

  bucket(): string {
    return this.location.bucket;
  }

  path(): string {
    return this.location.path();
  }

  name(): string {
    return path.lastComponent(this.location.path());
  }

  storage(): StorageManagement {
    return this.storageManagement;
  }

  protected newRef(
    service: StorageManagementImpl,
    area: string,
    location: Location
  ): StorageReference {
    return new StorageReferenceImpl(service, area, location);
  }

  child(childPath: string): StorageReference {
    validate('storagereference.child', [pathLengthSpec(forbiddenSymbol)], arguments);
    const newPath = path.child(this.location.path(), childPath);
    const location = new Location(this.location.bucket, newPath);
    return this.newRef(this.storageManagement, this._area, location);
  }

  async delete(): Promise<any> {
    this.throwIfDirectory_('be deleted', 'delete');
    return this.storageManagement.makeRequest(
      new DeleteRequest(this.storageManagement, this.location, this._area)
    );
  }

  async setMetaData(metaData: MetadataComplete): Promise<MetadataComplete> {
    this.throwIfDirectory_('set MetaData', 'setMetaData');
    return await this.storageManagement.makeRequest(
      new UpdateFileMetaDataRequest(this.storageManagement, this.location, metaData, this._area)
    );
  }

  async getMetaData(): Promise<MetadataComplete> {
    this.throwIfDirectory_('get MetaData', 'getMetaData');
    return await this.storageManagement.makeRequest(
      new GetFileMetadataRequest(this.storageManagement, this.location, this._area)
    );
  }

  async getDownloadURL(): Promise<string> {
    this.throwIfDirectory_('get download url', 'getDownloadURL');
    return this.storageManagement
      .makeRequest(new GetDownloadUrlRequest(this.storageManagement, this.location, this._area))
      .then(url => {
        if (url === null) {
          throw new AGCStorageError(AGCStorageErrorCode.NO_DOWNLOAD_URL);
        }
        return url;
      });
  }

  async download(
    localPath: string,
    progressCallback: (p: ProgressEvent) => void
  ): Promise<TransResult> {
    let downUrl = await this.getDownloadURL();
    let downloadConfig: request.DownloadConfig = {
      enableMetered: true,
      enableRoaming: true,
      url: downUrl,
      filePath: localPath
    };
    let hostname = url.URL.parseURL(downUrl)?.hostname;
    if (hostname) {
      downloadConfig.header = { "Host": hostname }
    }
    let downTask = await request.downloadFile(getContext(), downloadConfig);
    return new Promise((resolve, reject) => {
      downTask.on('progress', (receivedSize, totalSize) => {
        progressCallback?.call(this, {
          total: totalSize,
          loaded: receivedSize
        });
      });
      downTask.on('complete', () => {
        downTask
          .getTaskInfo()
          .then(taskInfo => {
            resolve({
              totalByteCount: taskInfo.downloadTotalBytes,
              bytesTransferred: taskInfo.downloadedBytes
            });
          })
          .catch(e => {
            reject(e);
          });
      });
      downTask.on('fail', (err: number) => {
        reject(`downTask error, number is ${err}`);
      })
    });
  }

  async list(options?: ListOptions): Promise<ListRefResult> {
    let maxResults = options?.maxResults;
    if (Number.isInteger(maxResults)) {
      if (maxResults <= 0 || maxResults > 1000) {
        throw new AGCStorageError(
          AGCStorageErrorCode.INVALID_ARGUMENT,
          'Invalid maxResults, valid maxResults should be within: [1-1000]'
        );
      }
      let listResult = await this.listFromServer(options?.pageMarker, maxResults);
      return listResult;
    }
    return this.recursiveFetchList(options?.pageMarker);
  }

  async recursiveFetchList(marker): Promise<ListRefResult> {
    let curPageRes = await this.listFromServer(marker);
    if (!curPageRes.pageMarker) {
      return curPageRes;
    }
    let restPageRes = await this.recursiveFetchList(curPageRes.pageMarker);
    return {
      dirList: [...curPageRes.dirList, ...restPageRes.dirList],
      fileList: [...curPageRes.fileList, ...restPageRes.fileList]
    };
  }

  async listFromServer(pageMarker, maxResults?): Promise<ListRefResult> {
    return this.storageManagement.makeRequest(
      new ListRequest(
        this.storageManagement,
        this.location,
        this._area,
        '/',
        pageMarker,
        maxResults
      )
    );
  }

  putData(data: Uint8Array | ArrayBuffer): UploadTaskImpl {
    this.throwIfDirectory_('put file', 'put');
    validate('storagereference.putData', [uploadDataSpec(), metadataSpec(true)], arguments);
    this.throwIfRoot_('putData');
    return new UploadTaskImpl(
      this.storageManagement,
      this.location,
      new CSBlob(data),
      null,
      this._area
    );
  }

  toString(): string {
    return 'grs://' + this.location.bucket + '/' + this.location.path();
  }

  private throwIfRoot_(name: string): void {
    if (this.location.path() === '') {
      throw new AGCStorageError(
        AGCStorageErrorCode.INVALID_OPERATION,
        `The operation' ${name} cannot be performed on a root reference.`
      );
    }
  }

  private throwIfDirectory_(name: string, func: string): void {
    if (this.location.path() === '' || this.location.path().endsWith('/')) {
      throw new AGCStorageError(
        AGCStorageErrorCode.INVALID_OPERATION,
        `Only file can ${name} and func ${func} don't supported at the root of bucket`
      );
    }
  }
}
