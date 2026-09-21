import { AGConnectAuthCredentialProvider } from '../../Auth';
import { PhoneUtil } from '../../utils/PhoneUtil';
import { AuthBaseRequest } from './AuthBaseRequest';

export class ResetPhonePasswordRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/reset-password';

  countryCode: string = '';
  phoneNumber: string = '';
  newPassword: string = '';
  verifyCode: string = '';

  async body(): Promise<any> {
    return {
      account: PhoneUtil.combinatePhone(this.countryCode, this.phoneNumber),
      password: this.newPassword,
      verifyCode: this.verifyCode,
      provider: AGConnectAuthCredentialProvider.Phone_Provider
    };
  }
}
