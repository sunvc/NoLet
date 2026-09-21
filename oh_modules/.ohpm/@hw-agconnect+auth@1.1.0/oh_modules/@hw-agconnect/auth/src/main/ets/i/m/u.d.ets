// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class RegisterUserRequest extends AuthBaseRequest {
    email: string;
    phone: string;
    password: string;
    verifyCode: string;
    provider: number;
    protected readonly URL_PATH_SURFFIX = "/user-register";
    private useJwt;
    body(): Promise<Record<string, object | number | string>>;
}
