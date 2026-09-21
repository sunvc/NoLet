import { EmailUser } from '../AuthInnerInterface';

export class EmailUserBuilder {
  private email: string = '';
  private password: string = '';
  private verifyCode: string = '';

  setEmail(email: string): EmailUserBuilder {
    this.email = email;
    return this;
  }

  setPassword(password: string): EmailUserBuilder {
    this.password = password;
    return this;
  }

  setVerifyCode(verifyCode: string): EmailUserBuilder {
    this.verifyCode = verifyCode;
    return this;
  }

  build(): EmailUser {
    return {
      email: this.email,
      password: this.password,
      verifyCode: this.verifyCode
    };
  }
}
