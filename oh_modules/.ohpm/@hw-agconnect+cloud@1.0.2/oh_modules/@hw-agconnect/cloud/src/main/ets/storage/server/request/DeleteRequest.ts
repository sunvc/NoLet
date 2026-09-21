import { CloudStorageRequest } from './CloudStorageRequest';
import { Location } from '../../implementation/location';
import * as UrlUtils from '../../utils/url';
import { StorageManagementImpl } from '../../implementation/storageManagementImpl';

export class DeleteRequest extends CloudStorageRequest<any> {
  constructor(storageManagement: StorageManagementImpl, location: Location, area: string) {
    super(storageManagement, location, UrlUtils.makeUrl(location.fullUrl()), 'DELETE', area);
    this.successCodes = [200, 204];
  }

  handle(res: any): void {}
}
