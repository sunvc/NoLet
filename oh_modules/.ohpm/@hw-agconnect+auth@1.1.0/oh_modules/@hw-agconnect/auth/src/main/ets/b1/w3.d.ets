// @keepTs
// @ts-nocheck
import { ReauthenticateRequest } from "../i/m/r3";
import { SignInRequest } from "../i/m/a1";
import { UserLinkRequest } from "../i/m/s3";
import { AccountCredential } from "./u3";
import { PhoneUser } from "../v";
export declare class PhoneAuthCredential extends AccountCredential {
    countryCode: string;
    phoneNumber: string;
    private TAG;
    constructor(p3: PhoneUser);
    getProvider(): number;
    prepareUserAuthRequest(request: SignInRequest): void;
    prepareUserReauthRequest(request: ReauthenticateRequest): void;
    prepareUserLinkRequest(request: UserLinkRequest): void;
    private generateExtraData;
}
