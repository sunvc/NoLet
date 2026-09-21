// @keepTs
// @ts-nocheck
import { ConnectRet } from "./y2";
export interface Ret {
    code: number;
    msg: string;
}
export interface RootObject {
    ret: Ret;
}
export declare class BaseResponse {
    root: RootObject | undefined;
    ret: ConnectRet;
    constructor();
    isSuccess(): boolean;
    getRet(): Ret;
    setRet(value: Ret): void;
    constructResponse(response: object): boolean;
}
