// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class UpdatePasswordRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-password";
    private verifyCode;
    private newPassword;
    private provider;
    getProvider(): number;
    setProvider(provider: number): void;
    setNewPassword(newPassword: string): void;
    setNewverifyCode(verifyCode: string): void;
    body(): Promise<Record<string, object | number | string>>;
}
