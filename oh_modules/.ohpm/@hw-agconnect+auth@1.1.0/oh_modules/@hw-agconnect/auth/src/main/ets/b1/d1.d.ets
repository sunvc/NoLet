// @keepTs
// @ts-nocheck
import { EmailAuthCredential } from "./v3";
export declare class EmailAuthProvider {
    /**
     * 通过邮箱和密码获取凭证
     * 如果创建用户时设置了密码，可以采用邮箱和密码登录
     *
     * @param email 邮箱
     * @param password 密码
     * @return Email凭证
     */
    static credentialWithPassword(email: string, password: string): EmailAuthCredential;
    /**
     * 通过邮箱和验证码获取凭证
     * 如果创建账户的时候没有设置过密码，则只能通过此接口进行登录
     *
     * @param email 邮箱
     * @param verifyCode 验证码 Link用户的时候必填
     * @return Email凭证
     */
    static credentialWithVerifyCode(email: string, k3: string): EmailAuthCredential;
    /**
     * 通过密码和验证码 双重验证获取凭证
     *
     * @param email 邮箱
     * @param password 密码
     * @param verifyCode  验证码
     * @returns Email凭证
     */
    static credentialWithPasswordAndVerifyCode(email: string, password: string, i3: string): EmailAuthCredential;
}
