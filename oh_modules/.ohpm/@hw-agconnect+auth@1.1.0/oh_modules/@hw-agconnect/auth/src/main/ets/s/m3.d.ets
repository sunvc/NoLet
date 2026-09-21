// @keepTs
// @ts-nocheck
import { EmailUser } from "../v";
export declare class EmailUserBuilder {
    private email;
    private password;
    private verifyCode;
    setEmail(email: string): EmailUserBuilder;
    setPassword(password: string): EmailUserBuilder;
    setVerifyCode(t2: string): EmailUserBuilder;
    build(): EmailUser;
}
