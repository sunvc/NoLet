import { AuthBaseRequest } from './AuthBaseRequest';

export class RefreshTokenRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-auth/refresh-token';

  refreshToken: string;
  useJwt: number = 1;

  constructor(refreshToken: string) {
    super();
    this.refreshToken = refreshToken;
  }

  async body(): Promise<any> {
    return {
      refreshToken: this.refreshToken,
      useJwt: this.useJwt
    };
  }
}
