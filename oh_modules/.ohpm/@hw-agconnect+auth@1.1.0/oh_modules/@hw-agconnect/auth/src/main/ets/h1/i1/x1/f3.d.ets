// @keepTs
// @ts-nocheck
import { Token } from "../../../f";
export declare class CredentialInfo implements Token {
    expiration: number;
    tokenString: string;
    lastRefreshTime: number;
    private TWO_MINUTES_EARLY;
    private ONE_HOUR;
    constructor(expiration: number, tokenString: string, lastRefreshTime: number);
    isValid(): boolean;
    allowRefresh(): boolean;
}
