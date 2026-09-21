// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class ResetPhonePasswordRequest extends AuthBaseRequest {
    countryCode: string;
    phoneNumber: string;
    newPassword: string;
    verifyCode: string;
    protected readonly URL_PATH_SURFFIX = "/reset-password";
    body(): Promise<Record<string, object | number | string>>;
}
