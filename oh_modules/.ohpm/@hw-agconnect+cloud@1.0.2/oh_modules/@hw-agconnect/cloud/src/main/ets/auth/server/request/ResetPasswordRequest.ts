import { AuthBaseRequest } from './AuthBaseRequest';

export class ResetPasswordRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/reset-password';

  account: string = '';
  newPassword: string = '';
  verifyCode: string = '';
  provider: number = -1;

  async body(): Promise<any> {
    return {
      // account: PhoneUtil.combinatePhone(this.countryCode, this.phoneNumber),
      account: this.account,
      password: this.newPassword,
      verifyCode: this.verifyCode,
      provider: this.provider
    };
  }
}
