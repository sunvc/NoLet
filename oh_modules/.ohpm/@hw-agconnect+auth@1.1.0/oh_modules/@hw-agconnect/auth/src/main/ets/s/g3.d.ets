// @keepTs
// @ts-nocheck
import { TokenResult } from "../f";
export declare enum TokenState {
    SIGNED_IN = 0,
    TOKEN_UPDATED = 1,
    TOKEN_INVALID = 2,
    SIGNED_OUT = 3
}
export declare class TokenImpl implements TokenResult {
    state: TokenState | undefined;
    expiration: number;
    tokenString: string;
    constructor(expiration: number, v2: string);
    getString(): string;
    getExpirePeriod(): number;
    getState(): TokenState | undefined;
    getToken(): string;
}
