import { AuthBaseRequest } from './AuthBaseRequest';

export class SignOutRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-signout';

  bodyAccessToken: string = '';

  refreshToken: string = '';

  async body(): Promise<any> {
    return {
      refreshToken: this.refreshToken,
      accessToken: this.bodyAccessToken
    };
  }
}
