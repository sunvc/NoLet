// @keepTs
// @ts-nocheck
export declare class UserStored {
    private name;
    private region;
    constructor(region: string);
    saveUser(info: string | null): Promise<void>;
    getLocalUser(): Promise<string | object | null>;
    deleteUserInfo(): Promise<void>;
}
