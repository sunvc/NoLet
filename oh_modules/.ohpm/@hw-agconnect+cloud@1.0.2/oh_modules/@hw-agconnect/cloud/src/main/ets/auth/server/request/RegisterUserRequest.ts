import { getAaid } from '@hw-agconnect/hmcore';
import { AuthBaseRequest } from './AuthBaseRequest';

export class RegisterUserRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-register';

  private useJwt: number = 1;

  email: string | undefined;
  phone: string | undefined;
  password: string | undefined;
  verifyCode: string | undefined;
  provider: number = -1;

  async body(): Promise<any> {
    return {
      email: this.email,
      phone: this.phone,
      password: this.password,
      verifyCode: this.verifyCode,
      useJwt: this.useJwt,
      provider: this.provider,
      aaid: getAaid()
    };
  }
}
