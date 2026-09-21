// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class SignInAnonymousRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-signin-anonymous";
    private provider;
    private extraData;
    private useJwt;
    setUseJwt(useJwt: number): void;
    getExtraData(): string;
    setExtraData(extraData: string): void;
    setProvider(provider: number): void;
    body(): Promise<Record<string, object | number | string>>;
}
