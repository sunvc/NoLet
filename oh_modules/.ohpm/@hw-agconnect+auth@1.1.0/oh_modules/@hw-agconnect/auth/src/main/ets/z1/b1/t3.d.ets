// @keepTs
// @ts-nocheck
import { OAuth2Credential } from "../../b1/q3";
import { ReauthenticateRequest } from "../../i/m/r3";
import { SignInRequest } from "../../i/m/a1";
import { UserLinkRequest } from "../../i/m/s3";
export declare class HwIdAuthCredential extends OAuth2Credential {
    private authCode;
    private TAG;
    constructor(authCode: string);
    getProvider(): number;
    prepareUserAuthRequest(request: SignInRequest): void;
    prepareUserReauthRequest(request: ReauthenticateRequest): void;
    prepareUserLinkRequest(request: UserLinkRequest): void;
    private generateExtraData;
}
