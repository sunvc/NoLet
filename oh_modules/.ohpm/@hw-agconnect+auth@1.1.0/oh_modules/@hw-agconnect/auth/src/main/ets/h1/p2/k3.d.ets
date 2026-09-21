// @keepTs
// @ts-nocheck
import { AGCError } from "./q2";
export declare enum q2 {
    INIT_ERROR = 1100001,
    JSON_FILE_ERROR = 1100002,
    DATASTORE_ERROR = 1100003
}
export declare function error(code: q2, message: string): AGCError;
