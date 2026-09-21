import { PhoneUserBuilder } from '../entity/PhoneUserBuilder';
import { PhoneAuthCredential } from './PhoneAuthCredential';

export class PhoneAuthProvider {
  /**
   * 通过手机和密码获取凭证
   * 如果创建用户时设置了密码，可以采用邮箱和密码登录
   *
   * @param countryCode 国家码
   * @param phoneNumber 手机号
   * @param password 密码
   * @return Email凭证
   */
  public static credentialWithPassword(
    countryCode: string,
    phoneNumber: string,
    password: string
  ): PhoneAuthCredential {
    // TODO 凭证类的继承关系后期需整改
    let user = new PhoneUserBuilder()
      .setCountryCode(countryCode)
      .setPhoneNumber(phoneNumber)
      .setPassword(password)
      .build();
    return new PhoneAuthCredential(user);
  }

  /**
   * 通过手机和验证码获取凭证
   * 如果创建账户的时候没有设置过密码，则只能通过此接口进行登录
   *
   * @param countryCode 国家码
   * @param phoneNumber 手机号
   * @param verifyCode 验证码 Link用户的时候必填
   * @return Email凭证
   */
  public static credentialWithVerifyCode(
    countryCode: string,
    phoneNumber: string,
    verifyCode: string
  ): PhoneAuthCredential {
    let user = new PhoneUserBuilder()
      .setCountryCode(countryCode)
      .setPhoneNumber(phoneNumber)
      .setVerifyCode(verifyCode)
      .build();
    return new PhoneAuthCredential(user);
  }

  /**
   * 通过密码和验证码 双重验证获取凭证
   *
   * @param countryCode 国家码
   * @param phoneNumber 手机号
   * @param password 密码
   * @param verifyCode  验证码
   * @returns Email凭证
   */
  public static credentialWithPasswordAndVerifyCode(
    countryCode: string,
    phoneNumber: string,
    password: string,
    verifyCode: string
  ): PhoneAuthCredential {
    let emailUser = new PhoneUserBuilder()
      .setCountryCode(countryCode)
      .setPhoneNumber(phoneNumber)
      .setPassword(password)
      .setVerifyCode(verifyCode)
      .build();
    return new PhoneAuthCredential(emailUser);
  }
}
