// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class UpdateEmailRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-phone-email";
    private newEmail;
    private newVerifyCode;
    private lang;
    setNewVerifyCode(newVerifyCode: string): void;
    setNewEmail(newEmail: string): void;
    setLang(lang: string): void;
    body(): Promise<Record<string, object | number | string>>;
}
