// @keepTs
// @ts-nocheck
import { PhoneUser } from "../v";
export declare class PhoneUserBuilder {
    private countryCode;
    private phoneNumber;
    private password;
    private verifyCode;
    setCountryCode(countryCode: string): PhoneUserBuilder;
    setPhoneNumber(phoneNumber: string): PhoneUserBuilder;
    setPassword(password: string): PhoneUserBuilder;
    setVerifyCode(u2: string): PhoneUserBuilder;
    build(): PhoneUser;
}
