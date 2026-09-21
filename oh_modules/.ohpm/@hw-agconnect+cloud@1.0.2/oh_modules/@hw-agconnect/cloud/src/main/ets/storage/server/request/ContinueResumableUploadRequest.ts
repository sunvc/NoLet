import { CloudStorageRequest } from './CloudStorageRequest';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';
import { Location } from '../../implementation/location';
import { MetadataComplete } from '../../storage';
import * as UrlUtils from '../../utils/url';
import * as MetadataUtils from './MetaDataUtils';
import { checkResumeHeader_, metadataForUpload_ } from './UploadUtils';
import { CSBlob } from '../../upload/file';
import { ResumableUploadStatus } from './UploadUtils';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class ContinueResumableUploadRequest extends CloudStorageRequest<ResumableUploadStatus> {
  private blob: CSBlob;
  private status_: ResumableUploadStatus;
  private bytesToUpload: number;

  constructor(
    storageManagement: StorageManagementImpl,
    location: Location,
    blob: CSBlob,
    chunkSize: number,
    area: string,
    body: Uint8Array,
    status: ResumableUploadStatus,
    bytesToUpload: number,
    metadata?: MetadataComplete | null,
    progressCallback?: (progressEvent: any) => void
  ) {
    super(storageManagement, location, UrlUtils.makeUrl(location.fullUrl()), 'PUT', area);
    this.status_ = status;
    this.bytesToUpload = bytesToUpload;
    this.blob = blob;
    const metadata_ = metadataForUpload_(blob, location, metadata);
    this.headers = {
      'x-agc-nsp-js': 'JSSDK',
      'X-Agc-File-Size': status.total.toString(),
      'X-Agc-File-Offset': status.current.toString(),
      'X-Agc-Sha256': blob.sha256(),
      ...metadata_['metadata']
    };
    this._body = (body as Uint8Array).buffer;
  }

  metadataHandler(res: any): MetadataComplete {
    const metadata = MetadataUtils.parseResponse(res);
    if (metadata == null) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    return metadata as MetadataComplete;
  }

  handle(res: any): ResumableUploadStatus {
    if (!res) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    res = JSON.parse(res);
    const uploadStatus = checkResumeHeader_(res, ['resumable', 'active', 'finalize']);
    const newCurrent = this.status_.current + this.bytesToUpload;
    const size = this.blob.size();
    let metadata;
    if (uploadStatus === 'finalize') {
      metadata = this.metadataHandler({ data: res.fileInfo });
    } else {
      metadata = null;
    }
    return new ResumableUploadStatus(newCurrent, size, uploadStatus === 'finalize', metadata);
  }
}
