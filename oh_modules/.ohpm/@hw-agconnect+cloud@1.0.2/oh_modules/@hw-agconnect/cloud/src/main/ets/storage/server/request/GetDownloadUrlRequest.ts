import { CloudStorageRequest } from './CloudStorageRequest';
import { Location } from '../../implementation/location';
import * as UrlUtils from '../../utils/url';
import { CloudStorageConfig } from '../../utils/CloudStorageConfig';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class GetDownloadUrlRequest extends CloudStorageRequest<string | null> {
  constructor(storageManagement: StorageManagementImpl, location: Location, area: string) {
    super(
      storageManagement,
      location,
      UrlUtils.makeUrl(location.fullUrl()) + '?token=create',
      'GET',
      area
    );
  }

  handle(res: any): string | null {
    if (!res) {
      throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
    }
    res = JSON.parse(res);
    const urlInfo = CloudStorageConfig.getInstance().getHostByRegion(this.area);
    return urlInfo.url + UrlUtils.makeUrl(this.location.fullUrl()) + '?token=' + res[0];
  }
}
