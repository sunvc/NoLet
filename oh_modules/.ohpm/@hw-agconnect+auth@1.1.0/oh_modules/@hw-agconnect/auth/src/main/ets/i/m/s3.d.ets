// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class UserLinkRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-link";
    private provider;
    private token;
    private extraData;
    private useJwt;
    setUseJwt(useJwt: number): void;
    setProvider(provider: number): void;
    setToken(token: string): void;
    getExtraData(): string;
    setExtraData(extraData: string): void;
    body(): Promise<Record<string, object | number | string>>;
}
