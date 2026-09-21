// @keepTs
// @ts-nocheck
import { AuthBackend } from "../i/j";
import { UserRawData } from "./q1";
import { AuthDefaultUser as AuthDefaultUser } from "./x4";
import { UserStored } from "../r1/s1";
export declare class UserManager {
    storedManager: UserStored | undefined;
    authBackend: AuthBackend | undefined;
    user: AuthDefaultUser | undefined;
    makeUserInstance(c8: UserRawData): Promise<AuthDefaultUser>;
    disposeUserInstance(): Promise<void>;
    currentUserInstance(): Promise<AuthDefaultUser | null>;
}
export declare class UserManagerBuilder {
    private manager;
    constructor();
    setAuthBackend(b8: AuthBackend): UserManagerBuilder;
    setStoredManager(a8: UserStored): UserManagerBuilder;
    build(): UserManager;
    private reset;
}
