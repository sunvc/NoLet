import { AuthBaseRequest } from './AuthBaseRequest';

export class DeleteUserRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-delete';
}
