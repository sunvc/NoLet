import { CloudStorageRequest } from './CloudStorageRequest';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';
import { Location } from '../../implementation/location';
import { MetadataComplete } from '../../storage';
import * as UrlUtils from '../../utils/url';
import { CSBlob } from '../../upload/file';
import { ResumableUploadStatus, checkResumeHeader_ } from './UploadUtils';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class ResumableUploadStatusRequest extends CloudStorageRequest<ResumableUploadStatus> {
  private blob: CSBlob;

  constructor(
    storageManagement: StorageManagementImpl,
    location: Location,
    blob: CSBlob,
    area: string,
    metadata?: MetadataComplete,
    delimiter?: string,
    marker?: string | null,
    maxKeys?: number | null
  ) {
    super(storageManagement, location, UrlUtils.makeUrl(location.fullUrl()), 'POST', area);
    this.blob = blob;
    this.headers = {
      'x-agc-nsp-js': 'JSSDK',
      'X-Agc-Upload-Protocol': 'resumable',
      'X-Agc-File-Size': blob.size(),
      'X-Agc-Sha256': blob.sha256()
    };
  }

  handle(res: any): ResumableUploadStatus {
    if (!res) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    res = JSON.parse(res);
    const uploadStatus = checkResumeHeader_(res, ['resumable', 'active', 'finalize']);
    if (uploadStatus === 'finalize') {
      return new ResumableUploadStatus(
        this.blob.size(),
        this.blob.size(),
        uploadStatus === 'finalize'
      );
    }
    let sizeString = res.receiveBytes;

    if (!sizeString) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }

    const size = Number(sizeString);
    if (isNaN(size)) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    return new ResumableUploadStatus(size, this.blob.size(), uploadStatus === 'finalize');
  }
}
