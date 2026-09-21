import { PhoneUtil } from '../../utils/PhoneUtil';
import { AuthBaseRequest } from './AuthBaseRequest';

export class UpdatePhoneRequest extends AuthBaseRequest {
  protected readonly URL_PATH_SURFFIX = '/user-phone-email';

  countryCode: string = '';
  newPhone: string = '';
  newVerifyCode: string = '';
  lang: string = '';

  async body(): Promise<any> {
    return {
      lang: this.lang,
      newPhone: PhoneUtil.combinatePhone(this.countryCode, this.newPhone),
      newVerifyCode: this.newVerifyCode
    };
  }
}
