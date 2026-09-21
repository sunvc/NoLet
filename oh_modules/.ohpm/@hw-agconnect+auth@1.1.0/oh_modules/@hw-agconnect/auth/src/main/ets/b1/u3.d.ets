// @keepTs
// @ts-nocheck
import { AGConnectAuthCredential } from "../v";
import { ReauthenticateRequest } from "../i/m/r3";
import { SignInRequest } from "../i/m/a1";
import { UserLinkRequest } from "../i/m/s3";
export declare abstract class AccountCredential implements AGConnectAuthCredential {
    password: string | undefined;
    verifyCode: string | undefined;
    getProvider(): number;
    /**
     * 此接口由内部使用
     *
     * @param request 登录请求
     */
    abstract prepareUserAuthRequest(request: SignInRequest): void;
    /**
     * 此接口由内部使用
     *
     * @param request 重认证请求
     */
    abstract prepareUserReauthRequest(request: ReauthenticateRequest): void;
    /**
     * 此接口由内部使用
     *
     * @param request 连接请求
     */
    abstract prepareUserLinkRequest(request: UserLinkRequest): void;
}
