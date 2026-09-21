import { AuthBaseRequest } from './AuthBaseRequest';

export class ReauthenticateRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-reauthenticate';

  private provider: number = -1;

  private token: string = '';

  private extraData: string = '';

  private autoCreateUser: boolean = false;

  private useJwt: number = 1;

  public setUseJwt(useJwt: number) {
    this.useJwt = useJwt;
  }

  public setExtraData(extraData: string): void {
    this.extraData = extraData;
  }

  public setAutoCreateUser(autoCreateUser: boolean): void {
    this.autoCreateUser = autoCreateUser;
  }

  public setProvider(provider: number): void {
    this.provider = provider;
  }

  public setToken(token: string): void {
    this.token = token;
  }

  async body(): Promise<any> {
    return {
      provider: this.provider,
      token: this.token,
      extraData: this.extraData,
      autoCreateUser: this.autoCreateUser ? 1 : 0,
      useJwt: this.useJwt
    };
  }
}
