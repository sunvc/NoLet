// @keepTs
// @ts-nocheck
export declare class ClientTokenStored {
    private name;
    saveClientToken(info: string): Promise<void>;
    getLocalClientToken(): Promise<string | object | null>;
}
