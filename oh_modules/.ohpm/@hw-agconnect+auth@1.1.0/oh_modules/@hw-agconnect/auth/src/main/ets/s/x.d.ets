// @keepTs
// @ts-nocheck
import { AuthUser, SignInResult } from "../f";
export declare class SignInResultImpl implements SignInResult {
    private user;
    constructor(user: AuthUser);
    /**
     * 返回当前登录的用户信息
     * @return 当前登录的用户信息
     */
    getUser(): AuthUser;
}
