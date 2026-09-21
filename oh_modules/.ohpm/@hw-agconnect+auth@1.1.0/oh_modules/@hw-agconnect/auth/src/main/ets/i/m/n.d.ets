// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class VerifyCodeRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/verify-code";
    private phone;
    private email;
    private action;
    private lang;
    private sendInterval;
    body(): Promise<Record<string, object | number | string>>;
    setPhone(phone: string): void;
    setEmail(email: string): void;
    setAction(action: number): void;
    setLang(lang: string): void;
    setSendInterval(sendInterval: number): void;
}
