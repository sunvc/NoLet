// @keepTs
// @ts-nocheck
import common from '@ohos.app.ability.common';
export declare class Preferences {
    static get(context: common.Context, fileName: string, key: string): Promise<string | Uint8Array>;
    static put(context: common.Context, fileName: string, key: string, value: string | Uint8Array): Promise<void>;
    static delete(context: common.Context, fileName: string, key: string): Promise<void>;
}
