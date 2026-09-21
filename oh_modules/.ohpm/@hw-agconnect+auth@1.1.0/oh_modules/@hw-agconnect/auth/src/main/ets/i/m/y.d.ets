// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class ResetPasswordRequest extends AuthBaseRequest {
    account: string;
    newPassword: string;
    verifyCode: string;
    provider: number;
    protected readonly URL_PATH_SURFFIX = "/reset-password";
    body(): Promise<Record<string, object | number | string>>;
}
