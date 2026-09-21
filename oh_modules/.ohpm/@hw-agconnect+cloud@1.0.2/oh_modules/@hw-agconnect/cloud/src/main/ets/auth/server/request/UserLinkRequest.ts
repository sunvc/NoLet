import { AuthBaseRequest } from './AuthBaseRequest';

export class UserLinkRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-link';

  private provider: number = -1;
  private token: string = '';
  private extraData: string = '';
  private useJwt: number = 1;

  public setUseJwt(useJwt: number): void {
    this.useJwt = useJwt;
  }

  public setProvider(provider: number): void {
    this.provider = provider;
  }

  public setToken(token: string): void {
    this.token = token;
  }

  public getExtraData(): string {
    return this.extraData;
  }

  public setExtraData(extraData: string): void {
    this.extraData = extraData;
  }

  async body(): Promise<any> {
    return {
      provider: this.provider,
      token: this.token,
      extraData: this.extraData,
      useJwt: this.useJwt
    };
  }
}
