import { CloudStorageRequest } from './CloudStorageRequest';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';
import { Location } from '../../implementation/location';
import { MetadataComplete } from '../../storage';
import * as MetadataUtils from './MetaDataUtils';
import * as UrlUtils from '../../utils/url';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class GetFileMetadataRequest extends CloudStorageRequest<MetadataComplete> {
  constructor(
    storageManagement: StorageManagementImpl,
    location: Location,
    area: string,
    delimiter?: string,
    marker?: string | null,
    maxKeys?: number | null
  ) {
    super(
      storageManagement,
      location,
      UrlUtils.makeUrl(location.fullUrl()) + '?metadata=query',
      'GET',
      area
    );
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
