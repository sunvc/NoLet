import { AegisAes } from '../base/aegis/AegisAes';

export class DecryptExclamationMark {
  private static PATTERN_ENCRYPT = new RegExp('^\\[!([A-Fa-f0-9]*)]');
  private static ITERATION_COUNT = 1000;
  private static IV_LENGTH = 16;
  private aesKey: string;

  private rxHex;
  private ryHex;
  private rzHex;
  private slHex;

  constructor(rxHex: string, ryHex: string, rzHex: string, slHex: string) {
    this.rxHex = rxHex;
    this.ryHex = ryHex;
    this.rzHex = rzHex;
    this.slHex = slHex;
  }

  static isMatch(cipher: string): boolean {
    return this.PATTERN_ENCRYPT.test(cipher);
  }

  async decrypt(raw: string): Promise<string> {
    if (this.isKeyValid()) {
      if (!this.aesKey) {
        this.aesKey = AegisAes.buildKey(
          this.rxHex,
          this.ryHex,
          this.rzHex,
          this.slHex,
          DecryptExclamationMark.ITERATION_COUNT
        );
      }
    }
    let rawString = this.getRawString(raw);
    let ivEndIndex = DecryptExclamationMark.IV_LENGTH * 2 + 2;
    if (rawString && rawString.length > ivEndIndex) {
      let iv = rawString.substring(2, ivEndIndex);
      let cipher = rawString.substring(ivEndIndex);
      return AegisAes.decryptWithIv(this.aesKey, iv, cipher);
    }
    return '';
  }

  isKeyValid() {
    if (this.rxHex && this.ryHex && this.rzHex && this.slHex && this.rxHex.length >= 64) {
      return true;
    }
    return false;
  }

  getRawString(raw: string) {
    let array = raw.match(DecryptExclamationMark.PATTERN_ENCRYPT);
    if (array && array.length > 1) {
      return array[1];
    }
    return null;
  }
}
