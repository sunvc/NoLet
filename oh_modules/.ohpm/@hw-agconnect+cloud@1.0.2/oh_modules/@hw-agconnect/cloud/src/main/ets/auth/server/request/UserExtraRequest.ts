import { AuthBaseRequest } from './AuthBaseRequest';

export class UserExtraRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX: string = '/user-profile';
}
