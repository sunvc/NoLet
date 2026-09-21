import { bytesToHex, hexToBytes } from '../crypto/Hex';
import { getKey } from '../crypto/Keys';
import { FrameworkCrypto } from './FrameworkCrypto';
import agccrypto from 'libagccrypto.so';

export class AegisAes {
  public static buildKey(
    rxHex: string,
    ryHex: string,
    rzHex: string,
    slHex: string,
    iterationCount: number
  ): string {
    let password = getKey(hexToBytes(rxHex), hexToBytes(ryHex), hexToBytes(rzHex));
    return agccrypto.ohGenPbkdf2(bytesToHex(password), slHex, iterationCount);
  }

  public static async decryptWithIv(workKey: string, ivHex: string, cipher: string) {
    let result = await FrameworkCrypto.ohGenAesCbcDecryptWithIv(cipher, workKey, ivHex);
    if (result == undefined || result == '') {
      return cipher;
    }
    return result;
  }

  public static async encryptWithIv(workKey: string, ivHex: string, cipher: string) {
    let result = await FrameworkCrypto.ohGenAesCbcEncryptWithIv(cipher, workKey, ivHex);
    return result ? result : cipher;
  }
}
