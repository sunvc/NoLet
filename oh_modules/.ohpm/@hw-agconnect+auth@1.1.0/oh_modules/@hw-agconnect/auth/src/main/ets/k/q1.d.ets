// @keepTs
// @ts-nocheck
export interface UserRawData {
    anonymous: boolean;
    uid: string;
    displayName?: string;
    photoUrl?: string;
    email?: string;
    phone?: string;
    providerId: string;
    emailVerified?: number;
    passwordSetted?: number;
    providerInfo?: Array<Map<string, string>>;
    accessToken: string;
    accessTokenValidPeriod: number;
    refreshToken: string;
    startTime: number;
}
