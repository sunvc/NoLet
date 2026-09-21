import { Logger } from '@hw-agconnect/hmcore';
import { Storage } from '../../../storage/storage';
import { CloudGlobalConfig } from '../../../utils/CloudGlobalConfig';

const TAG: string = 'CloudStorageCaller';

export class CloudStorageCaller {
  async getDownloadURLs(
    fileIds: string | string[],
    config: CloudGlobalConfig
  ): Promise<{ [key: string]: string }> {
    if (fileIds === undefined || fileIds == null) {
      // 类型不合法
      return Promise.reject('');
    }

    let isPatch: boolean = true;
    let realFileIds: string[] = [];
    // 如果传入单个
    if ((typeof fileIds === 'string' || fileIds instanceof String) && this.checkFileId(fileIds)) {
      realFileIds.push(fileIds as string);
      isPatch = false;
    }
    // 如果传入批量
    if (fileIds instanceof Array) {
      let that = this;
      // 去重+去不合法
      fileIds.forEach(function (item) {
        if (that.checkFileId(item) && !realFileIds.includes(item)) {
          realFileIds.push(item);
        }
      });
    }
    if (realFileIds.length === 0) {
      return Promise.reject('');
    }

    return this.getMultiDownloadURL(realFileIds, isPatch, config);
  }

  private async getMultiDownloadURL(
    fileIds: string[],
    isPatch: boolean,
    config: CloudGlobalConfig
  ): Promise<{ [key: string]: string }> {
    let res: { [key: string]: string } = {};
    let getUrlPromises = [];
    let cloudStorageList: { [key: string]: any } = {};
    for (let item of fileIds) {
      let bucket: string = this.getBucketName(item);
      if (!cloudStorageList[bucket]) {
        let cloudStorage: Storage = config.storage(bucket);
        cloudStorageList[bucket] = cloudStorage;
      }
      // 并发请求
      let promise = new Promise<void>((resolve, reject) => {
        let storage: Storage = cloudStorageList[bucket];
        if (!storage) {
          return reject('');
        }

        storage
          .getDownloadURL(this.getPath(item))
          .then(url => {
            res[item as string] = url;
            resolve();
          })
          .catch(e => {
            Logger.error(
              TAG,
              'file: ' + getAnonymizeFileName(item) + ' get url failed, cause: ' + e.message
            );
            if (isPatch) {
              resolve();
            } else {
              // 如果单个要报错
              reject('');
            }
          });
      });
      getUrlPromises.push(promise);
    }
    await Promise.all(getUrlPromises);
    return res;
  }

  private checkFileId(fileId: any): boolean {
    if (typeof fileId === 'string' || fileId instanceof String) {
      let parts = fileId.split('/');
      return (
        parts &&
        parts.length > 1 &&
        parts[0].trim().length > 0 &&
        parts[parts.length - 1].trim().length > 0 &&
        -1 === parts.findIndex(item => item.length === 0)
      );
    }
    return false;
  }

  private getBucketName(fileId: string): string {
    let parts = fileId.split('/');
    return parts[0].trim();
  }

  private getPath(fileId: string): string {
    let parts = fileId.split('/');
    parts.splice(0, 1);
    return parts.join('/');
  }
}

// 获取匿名的文件名称用于打印日志
function getAnonymizeFileName(fileId: string): string {
  let parts = fileId.split('/');
  let fileNameWithSuffix = parts[parts.length - 1];
  if (fileNameWithSuffix && fileNameWithSuffix.length > 0) {
    let index = fileNameWithSuffix.lastIndexOf('.');
    let fileName = index >= 0 ? fileNameWithSuffix.substring(0, index) : fileNameWithSuffix;
    let suffix = index >= 0 ? fileNameWithSuffix.substring(index) : '';
    if (fileName.length > 3) {
      return '***' + fileName.substring(3) + suffix;
    } else {
      return '*' + fileName.substring(1) + suffix;
    }
  }
  return '*';
}
