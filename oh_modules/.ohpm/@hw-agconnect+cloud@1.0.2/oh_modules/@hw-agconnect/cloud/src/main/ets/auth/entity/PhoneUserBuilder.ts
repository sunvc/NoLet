import { PhoneUser } from '../AuthInnerInterface';
import { PhoneUtil } from '../utils/PhoneUtil';

export class PhoneUserBuilder {
  private countryCode: string = '';
  private phoneNumber: string = '';
  private password: string = '';
  private verifyCode: string = '';

  setCountryCode(countryCode: string): PhoneUserBuilder {
    this.countryCode = countryCode;
    return this;
  }

  setPhoneNumber(phoneNumber: string): PhoneUserBuilder {
    this.phoneNumber = phoneNumber;
    return this;
  }

  setPassword(password: string): PhoneUserBuilder {
    this.password = password;
    return this;
  }

  setVerifyCode(verifyCode: string): PhoneUserBuilder {
    this.verifyCode = verifyCode;
    return this;
  }

  build(): PhoneUser {
    return {
      countryCode: this.countryCode,
      phoneNumber: this.phoneNumber,
      password: this.password,
      verifyCode: this.verifyCode,

      getPhone(): string {
        return PhoneUtil.combinatePhone(this.countryCode, this.phoneNumber);
      }
    };
  }
}
