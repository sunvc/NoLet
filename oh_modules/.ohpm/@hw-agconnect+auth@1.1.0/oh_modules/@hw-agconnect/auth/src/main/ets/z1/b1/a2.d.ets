// @keepTs
// @ts-nocheck
import { HwIdAuthCredential } from "./t3";
export declare class HwIdAuthProvider {
    /**
     * 登录凭证构造器
     *
     * @param authCode 由HMS SDK授权后获得的authCode
     * @return 用于登录的凭证
     */
    static credentialWithToken(authCode: string): HwIdAuthCredential;
}
