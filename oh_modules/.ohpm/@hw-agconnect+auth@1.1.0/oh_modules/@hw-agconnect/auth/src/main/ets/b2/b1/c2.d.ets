// @keepTs
// @ts-nocheck
import { SelfBuildAuthCredential } from "./x3";
export declare class SelfBuildAuthProvider {
    /**
     * 登录凭证构造器
     *
     * @param accessToken 由用户提供的JWT token
     * @return 用于登录的凭证
     */
    static credentialWithToken(accessToken: string): SelfBuildAuthCredential;
}
