// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class UpdatePhoneRequest extends AuthBaseRequest {
    countryCode: string;
    newPhone: string;
    newVerifyCode: string;
    lang: string;
    protected readonly URL_PATH_SURFFIX = "/user-phone-email";
    body(): Promise<Record<string, object | number | string>>;
}
