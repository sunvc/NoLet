import { Logger } from '@hw-agconnect/hmcore';
import { ReauthenticateRequest } from '../server/request/ReauthenticateRequest';
import { SignInRequest } from '../server/request/SignInRequest';
import { UserLinkRequest } from '../server/request/UserLinkRequest';
import { PhoneUtil } from '../utils/PhoneUtil';
import { AccountCredential } from './AccountCredential';
import { AGConnectAuthCredentialProvider, PhoneUser } from '../AuthInnerInterface';

export class PhoneAuthCredential extends AccountCredential {
  private TAG: string = 'PhoneAuthCredential';
  countryCode: string;
  phoneNumber: string;

  constructor(phoneUser: PhoneUser) {
    super();
    this.countryCode = phoneUser.countryCode;
    this.phoneNumber = phoneUser.phoneNumber;
    this.password = phoneUser.password;
    this.verifyCode = phoneUser.verifyCode;
  }

  getProvider(): number {
    return AGConnectAuthCredentialProvider.Phone_Provider;
  }

  private generateExtraData(): string {
    return JSON.stringify({
      password: this.password,
      verifyCode: this.verifyCode
    });
  }

  public prepareUserAuthRequest(request: SignInRequest): void {
    Logger.info(this.TAG, 'prepareUserAuthRequest');
    request.setProvider(AGConnectAuthCredentialProvider.Phone_Provider);
    request.setToken(PhoneUtil.combinatePhone(this.countryCode, this.phoneNumber));
    request.setExtraData(this.generateExtraData());
  }

  public prepareUserReauthRequest(request: ReauthenticateRequest): void {
    request.setProvider(AGConnectAuthCredentialProvider.Phone_Provider);
    request.setToken(PhoneUtil.combinatePhone(this.countryCode, this.phoneNumber));
    request.setExtraData(this.generateExtraData());
  }

  public prepareUserLinkRequest(request: UserLinkRequest): void {
    request.setProvider(AGConnectAuthCredentialProvider.Phone_Provider);
    request.setToken(PhoneUtil.combinatePhone(this.countryCode, this.phoneNumber));
    request.setExtraData(this.generateExtraData());
  }
}
