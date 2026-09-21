import { AuthBaseRequest } from './AuthBaseRequest';

export class UpdateEmailRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-phone-email';

  private newEmail: string = '';
  private newVerifyCode: string = '';
  private lang: string = '';

  public setNewVerifyCode(newVerifyCode: string): void {
    this.newVerifyCode = newVerifyCode;
  }

  public setNewEmail(newEmail: string): void {
    this.newEmail = newEmail;
  }

  public setLang(lang: string): void {
    this.lang = lang;
  }

  async body(): Promise<any> {
    return {
      lang: this.lang,
      newEmail: this.newEmail,
      newVerifyCode: this.newVerifyCode
    };
  }
}
