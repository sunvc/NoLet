// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class ReauthenticateRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-reauthenticate";
    private provider;
    private token;
    private extraData;
    private autoCreateUser;
    private useJwt;
    setUseJwt(useJwt: number): void;
    setExtraData(extraData: string): void;
    setAutoCreateUser(autoCreateUser: boolean): void;
    setProvider(provider: number): void;
    setToken(token: string): void;
    body(): Promise<Record<string, object | string | number>>;
}
