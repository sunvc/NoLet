// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class SignInRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-signin";
    private provider;
    private token;
    private extraData;
    private autoCreateUser;
    private useJwt;
    setUseJwt(useJwt: number): void;
    getExtraData(): string;
    setExtraData(extraData: string): void;
    setAutoCreateUser(autoCreateUser: boolean): void;
    setProvider(provider: number): void;
    setToken(token: string): void;
    body(): Promise<Record<string, object | number | string>>;
}
