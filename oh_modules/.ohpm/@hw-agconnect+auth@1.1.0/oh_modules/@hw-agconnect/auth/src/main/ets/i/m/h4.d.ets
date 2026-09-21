// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class UserUnlinkRequest extends AuthBaseRequest {
    protected readonly URL_PATH_SURFFIX = "/user-unlink";
    private provider;
    getProvider(): number;
    setProvider(provider: number): void;
    queryParam(): string;
}
