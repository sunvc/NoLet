import { Logger } from '@hw-agconnect/hmcore';
import { ReauthenticateRequest } from '../server/request/ReauthenticateRequest';
import { SignInRequest } from '../server/request/SignInRequest';
import { UserLinkRequest } from '../server/request/UserLinkRequest';
import { AccountCredential } from './AccountCredential';
import { AGConnectAuthCredentialProvider, EmailUser } from '../AuthInnerInterface';

export class EmailAuthCredential extends AccountCredential {
  private TAG: string = 'EmailAuthCredential';
  email: string;

  constructor(emailUser: EmailUser) {
    super();
    this.email = emailUser.email;
    this.password = emailUser.password;
    this.verifyCode = emailUser.verifyCode;
  }

  getProvider(): number {
    return AGConnectAuthCredentialProvider.Email_Provider;
  }

  private generateExtraData(): string {
    return JSON.stringify({
      password: this.password,
      verifyCode: this.verifyCode
    });
  }

  public prepareUserAuthRequest(request: SignInRequest): void {
    Logger.info(this.TAG, 'prepareUserAuthRequest');
    request.setProvider(AGConnectAuthCredentialProvider.Email_Provider);
    request.setToken(this.email);
    request.setExtraData(this.generateExtraData());
  }

  public prepareUserReauthRequest(request: ReauthenticateRequest): void {
    request.setProvider(AGConnectAuthCredentialProvider.Email_Provider);
    request.setToken(this.email);
    request.setExtraData(this.generateExtraData());
  }

  public prepareUserLinkRequest(request: UserLinkRequest): void {
    request.setProvider(AGConnectAuthCredentialProvider.Email_Provider);
    request.setToken(this.email);
    request.setExtraData(this.generateExtraData());
  }
}
