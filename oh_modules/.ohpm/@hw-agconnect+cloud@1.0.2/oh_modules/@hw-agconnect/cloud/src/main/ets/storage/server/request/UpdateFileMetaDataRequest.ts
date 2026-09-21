import { CloudStorageRequest } from './CloudStorageRequest';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';
import { Location } from '../../implementation/location';
import { MetadataComplete } from '../../storage';
import * as MetadataUtils from './MetaDataUtils';
import * as UrlUtils from '../../utils/url';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class UpdateFileMetaDataRequest extends CloudStorageRequest<MetadataComplete> {
  constructor(
    storageManagement: StorageManagementImpl,
    location: Location,
    metadata: MetadataComplete,
    area: string,
    delimiter?: string,
    marker?: string,
    maxKeys?: number
  ) {
    super(
      storageManagement,
      location,
      UrlUtils.makeUrl(location.fullUrl()) + '?metadata=update',
      'GET',
      area
    );

    this.headers = { 'x-agc-nsp-js': 'JSSDK', ...MetadataUtils.parseMetadata(metadata) };
  }

  handle(res: any): MetadataComplete {
    if (!res) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    res = JSON.parse(res);
    const metadata = MetadataUtils.parseResponse(res);
    if (metadata == null) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    return metadata as MetadataComplete;
  }
}
