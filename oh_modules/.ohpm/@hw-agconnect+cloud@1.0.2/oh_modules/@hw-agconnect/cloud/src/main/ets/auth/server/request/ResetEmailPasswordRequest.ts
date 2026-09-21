import { AGConnectAuthCredentialProvider } from '../../Auth';
import { AuthBaseRequest } from './AuthBaseRequest';

export class ResetEmailPasswordRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/reset-password';

  email: string = '';
  newPassword: string = '';
  verifyCode: string = '';

  async body(): Promise<any> {
    return {
      account: this.email,
      password: this.newPassword,
      verifyCode: this.verifyCode,
      provider: AGConnectAuthCredentialProvider.Email_Provider
    };
  }
}
