// @keepTs
// @ts-nocheck
import { AGCError } from "../h1/p2/q2";
import { AuthErrorCode } from "./t1";
export declare class AGCAuthError extends AGCError {
    constructor(error: AuthErrorCode);
}
