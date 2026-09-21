// @keepTs
// @ts-nocheck
import { AuthBaseRequest } from "./y3";
export declare class RefreshTokenRequest extends AuthBaseRequest {
    refreshToken: string;
    useJwt: number;
    protected readonly URL_PATH_SURFFIX = "/user-auth/refresh-token";
    constructor(refreshToken: string);
    body(): Promise<Record<string, object | string | number>>;
}
