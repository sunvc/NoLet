import { AuthBaseRequest } from './AuthBaseRequest';

export class UserUnlinkRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-unlink';
  private provider: number = -1;

  public getProvider(): number {
    return this.provider;
  }

  public setProvider(provider: number): void {
    this.provider = provider;
  }

  queryParam(): string {
    return super.queryParam() + '&provider=' + this.provider;
  }
}
