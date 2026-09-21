export class PhoneUtil {
  public static combinatePhone(countryCode: string, phoneNumber: string): string {
    if (countryCode != null && !countryCode.startsWith('+')) {
      countryCode = '+' + countryCode;
    }
    return countryCode + '-' + phoneNumber;
  }
}
