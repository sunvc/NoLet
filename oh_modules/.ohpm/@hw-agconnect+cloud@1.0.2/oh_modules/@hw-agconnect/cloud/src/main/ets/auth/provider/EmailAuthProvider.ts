import { EmailUserBuilder } from '../entity/EmailUserBuilder';
import { EmailAuthCredential } from './EmailAuthCredential';

export class EmailAuthProvider {
  /**
   * 通过邮箱和密码获取凭证
   * 如果创建用户时设置了密码，可以采用邮箱和密码登录
   *
   * @param email 邮箱
   * @param password 密码
   * @return Email凭证
   */
  public static credentialWithPassword(email: string, password: string): EmailAuthCredential {
    // TODO 凭证类的继承关系后期需整改
    let emailUser = new EmailUserBuilder().setEmail(email).setPassword(password).build();
    return new EmailAuthCredential(emailUser);
  }

  /**
   * 通过邮箱和验证码获取凭证
   * 如果创建账户的时候没有设置过密码，则只能通过此接口进行登录
   *
   * @param email 邮箱
   * @param verifyCode 验证码 Link用户的时候必填
   * @return Email凭证
   */
  public static credentialWithVerifyCode(email: string, verifyCode: string): EmailAuthCredential {
    let emailUser = new EmailUserBuilder().setEmail(email).setVerifyCode(verifyCode).build();
    return new EmailAuthCredential(emailUser);
  }

  /**
   * 通过密码和验证码 双重验证获取凭证
   *
   * @param email 邮箱
   * @param password 密码
   * @param verifyCode  验证码
   * @returns Email凭证
   */
  public static credentialWithPasswordAndVerifyCode(
    email: string,
    password: string,
    verifyCode: string
  ): EmailAuthCredential {
    let emailUser = new EmailUserBuilder()
      .setEmail(email)
      .setPassword(password)
      .setVerifyCode(verifyCode)
      .build();
    return new EmailAuthCredential(emailUser);
  }
}
