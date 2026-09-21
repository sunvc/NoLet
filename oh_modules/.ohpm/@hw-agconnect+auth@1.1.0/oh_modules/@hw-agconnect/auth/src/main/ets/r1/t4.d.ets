// @keepTs
// @ts-nocheck
import common from '@ohos.app.ability.common';
export declare class FileStored {
    static readFile(context: common.Context, fileName: string, key: string): Promise<string>;
    static writeFile(context: common.Context, fileName: string, key: string, value: string): Promise<void>;
    static deleteFile(context: common.Context, fileName: string, key: string): Promise<void>;
}
