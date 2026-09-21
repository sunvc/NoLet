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
  // for providerService
  providerInfo?: Array<{ [key: string]: string }>;
  // for tokenService
  accessToken: string;
  accessTokenValidPeriod: number;
  refreshToken: string;
  startTime: number;
}
