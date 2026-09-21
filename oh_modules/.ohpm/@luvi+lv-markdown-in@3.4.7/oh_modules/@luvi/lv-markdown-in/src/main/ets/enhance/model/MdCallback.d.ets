// @keepTs
// @ts-nocheck
export interface MdCallback {
    complete?: () => void;
    fail?: (code: number, message: string) => void;
}
