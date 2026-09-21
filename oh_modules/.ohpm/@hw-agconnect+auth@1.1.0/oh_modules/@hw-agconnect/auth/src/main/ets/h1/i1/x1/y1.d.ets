// @keepTs
// @ts-nocheck
import { Token } from "../../../f";
export interface NetCredential {
    expires_in: number;
    access_token: string;
}
export interface NetCredentialInfo {
    expiration: number;
    tokenString: string;
    lastRefreshTime: number;
}
declare class Credential {
    private clientTokenStorage;
    getToken(forceRefresh: boolean, region: string): Promise<Token>;
}
declare const _default: Credential;
export default _default;
