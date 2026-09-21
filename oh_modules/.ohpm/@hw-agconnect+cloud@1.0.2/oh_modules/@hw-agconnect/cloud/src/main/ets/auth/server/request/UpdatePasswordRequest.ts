import { AuthBaseRequest } from './AuthBaseRequest';

export class UpdatePasswordRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-password';

  private verifyCode: string = '';

  private newPassword: string = '';

  private provider: number = 0;

  public getProvider(): number {
    return this.provider;
  }

  public setProvider(provider: number): void {
    this.provider = provider;
  }

  public setNewPassword(newPassword: string): void {
    this.newPassword = newPassword;
  }

  public setNewverifyCode(verifyCode: string): void {
    this.verifyCode = verifyCode;
  }

  async body(): Promise<any> {
    return {
      provider: this.provider,
      verifyCode: this.verifyCode,
      newPassword: this.newPassword
    };
  }
}
