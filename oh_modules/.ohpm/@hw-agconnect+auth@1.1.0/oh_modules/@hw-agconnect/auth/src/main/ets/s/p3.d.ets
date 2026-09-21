// @keepTs
// @ts-nocheck
export declare class UserInfo {
    private uid;
    private displayName;
    private photoUrl;
    private phone;
    private email;
    private provider;
    private openId;
    private emailVerified;
    private passwordSetted;
    constructor();
    getUid(): string;
    setUid(uid: string): void;
    getDisplayName(): string;
    setDisplayName(displayName: string): void;
    getPhotoUrl(): string;
    setPhotoUrl(b3: string): void;
    getPhone(): string;
    setPhone(phone: string): void;
    getEmail(): string;
    setEmail(email: string): void;
    getProvider(): number;
    setProvider(provider: number): void;
    getOpenId(): string;
    setOpenId(a3: string): void;
    getEmailVerified(): number;
    setEmailVerified(z2: number): void;
    getPasswordSetted(): number;
    setPasswordSetted(w2: number): void;
}
