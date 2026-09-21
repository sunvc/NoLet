import { CloudStorageRequest } from './CloudStorageRequest';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';
import { Location } from '../../implementation/location';
import { MetadataComplete } from '../../storage';
import * as MetadataUtils from './MetaDataUtils';
import * as UrlUtils from '../../utils/url';
import { CSBlob } from '../../upload/file';
import { metadataForUpload_ } from './UploadUtils';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class MultipartUploadRequest extends CloudStorageRequest<MetadataComplete> {
  constructor(
    storageManagement: StorageManagementImpl,
    location: Location,
    blob: CSBlob,
    area: string,
    metadata?: MetadataComplete | null,
    delimiter?: string,
    marker?: string | null,
    maxKeys?: number | null
  ) {
    super(storageManagement, location, UrlUtils.makeUrl(location.fullUrl()), 'PUT', area);
    const body = CSBlob.getBlob(blob);
    if (body === null) {
      throw new AGCStorageError(AGCStorageErrorCode.CANNOT_SLICE_BLOB);
    }
    const metadata_ = metadataForUpload_(blob, location, metadata);
    this.headers = {
      'x-agc-nsp-js': 'JSSDK',
      ...metadata_['metadata']
    };
    this._body = (body.uploadData() as Uint8Array).buffer;
  }

  handle(res: any): MetadataComplete {
    if (!res) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    res = JSON.parse(res);
    const metadata = MetadataUtils.parseResponse(res.fileInfo);
    if (metadata == null) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    return metadata as MetadataComplete;
  }
}
