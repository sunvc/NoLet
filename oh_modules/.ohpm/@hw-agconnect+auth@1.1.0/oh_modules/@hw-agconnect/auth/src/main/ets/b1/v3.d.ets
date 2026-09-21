// @keepTs
// @ts-nocheck
import { ReauthenticateRequest } from "../i/m/r3";
import { SignInRequest } from "../i/m/a1";
import { UserLinkRequest } from "../i/m/s3";
import { AccountCredential } from "./u3";
import { EmailUser } from "../v";
export declare class EmailAuthCredential extends AccountCredential {
    email: string;
    private TAG;
    constructor(h3: EmailUser);
    getProvider(): number;
    prepareUserAuthRequest(request: SignInRequest): void;
    prepareUserReauthRequest(request: ReauthenticateRequest): void;
    prepareUserLinkRequest(request: UserLinkRequest): void;
    private generateExtraData;
}
