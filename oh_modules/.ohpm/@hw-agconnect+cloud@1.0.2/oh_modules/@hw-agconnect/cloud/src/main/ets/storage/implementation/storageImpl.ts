import {
  MetadataComplete,
  Storage,
  StorageOptions,
  ListParam,
  UpdateMetaDataParam,
  ProgressEvent,
  UploadParam,
  DownloadParam,
  TransResult,
  ListResult
} from '../storage';
import { StorageManagementImpl } from './storageManagementImpl';
import { StorageReference, ListRefResult } from '../interface/innerInterface';
import { FileUtil } from '../utils/fileUtils';

export class StorageImpl implements Storage {
  private storageManagementImpl: StorageManagementImpl;

  constructor(region: string, options?: StorageOptions) {
    this.storageManagementImpl = new StorageManagementImpl(region, options?.bucket);
  }

  async upload(uploadParam: UploadParam): Promise<TransResult> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(
      uploadParam.cloudPath
    );
    let fileData: Uint8Array = await FileUtil.readFile(uploadParam.localPath);
    let uploadTask = ref.putData(fileData);
    uploadTask.on('progress', (uploadSize, totalSize) => {
      let event: ProgressEvent = {
        loaded: uploadSize,
        total: totalSize
      };
      uploadParam.onUploadProgress?.call(this, event);
    });
    return new Promise((resolve, reject) => {
      uploadTask
        .then(res => {
          let upRes: TransResult = {
            bytesTransferred: res.bytesTransferred,
            totalByteCount: res.totalByteCount
          };
          resolve(upRes);
        })
        .catch(error => {
          reject(error);
        });
    });
  }

  async download(downloadParam: DownloadParam): Promise<TransResult> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(
      downloadParam.cloudPath
    );
    return ref.download(downloadParam.localPath, downloadParam.onDownloadProgress);
  }

  async delete(cloudPath: string): Promise<void> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(cloudPath);
    return ref.delete();
  }

  async getDownloadURL(cloudPath: string): Promise<string> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(cloudPath);
    return ref.getDownloadURL();
  }

  async list(listParam?: ListParam): Promise<ListResult> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(
      listParam?.cloudPath
    );
    let refResult = await ref.list({
      pageMarker: listParam?.pageMarker,
      maxResults: listParam?.maxResults
    });
    return {
      dirList: refResult?.dirList?.map(v => v.path()),
      fileList: refResult?.fileList?.map(v => v.path()),
      pageMarker: refResult?.pageMarker
    };
  }

  async root(): Promise<string> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference();
    return ref.path();
  }

  async setMetaData(metaDataParam: UpdateMetaDataParam): Promise<MetadataComplete> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(
      metaDataParam.cloudPath
    );
    return ref.setMetaData(metaDataParam.metaData as MetadataComplete);
  }

  async getMetaData(cloudPath: string): Promise<MetadataComplete> {
    let ref: StorageReference = await this.storageManagementImpl.storageReference(cloudPath);
    return ref.getMetaData();
  }
}
