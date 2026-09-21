import { getAaid } from '@hw-agconnect/hmcore';
import { AuthBaseRequest } from './AuthBaseRequest';
import { AGConnectAuthCredentialProvider } from '../../AuthInnerInterface';

export class SignInAnonymousRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-signin-anonymous';

  private provider: number = AGConnectAuthCredentialProvider.Anonymous;

  private token: string = '';

  private extraData: string = '';

  private useJwt: number = 1;

  public setUseJwt(useJwt: number) {
    this.useJwt = useJwt;
  }

  public getExtraData(): string {
    return this.extraData;
  }

  public setExtraData(extraData: string): void {
    this.extraData = extraData;
  }

  public setProvider(provider: number): void {
    this.provider = provider;
  }

  public setToken(token: string): void {
    this.token = token;
  }

  public async body(): Promise<any> {
    return {
      provider: this.provider,
      token: await getAaid(),
      extraData: this.extraData,
      useJwt: this.useJwt
    };
  }
}
