// @keepTs
// @ts-nocheck
import { Token } from "../../../f";
export declare class TokenImpl implements Token {
    expiration: number;
    tokenString: string;
    constructor(expiration: number, tokenString: string);
}
