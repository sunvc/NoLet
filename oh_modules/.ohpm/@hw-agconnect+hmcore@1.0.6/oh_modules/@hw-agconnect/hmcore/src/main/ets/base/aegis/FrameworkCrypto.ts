import cryptoFramework from '@ohos.security.cryptoFramework';
import {
  hexStringToUint8Array,
  stringToUint8Array,
  uint8ArrayTohexString,
  uint8ArrayToString
} from '../crypto/Unit8ArrayUtil';

export class FrameworkCrypto {
  static async ohGenAesCbcEncryptWithIv(
    plain: string,
    workKey: string,
    iv: string
  ): Promise<string> {
    if (!plain || !workKey || !iv) {
      return plain;
    }
    let result = '';

    // 创建对称密钥生成器
    let symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    let keyDataBlob = { data: hexStringToUint8Array(workKey) };
    let sysKey = await symKeyGenerator.convertKey(keyDataBlob);

    // 生成加解密生成器
    let cipherAlgName = 'AES256|CBC|PKCS5';
    let params = { iv: { data: hexStringToUint8Array(iv) }, algName: 'IvParamsSpec' };

    // 创建Cipher对象
    let globalCipher = cryptoFramework.createCipher(cipherAlgName);

    // init
    await globalCipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, sysKey, params);

    // update  算法库不限定update的次数和每次加解密的数据量，需要业务验证大数据量情况下的性能
    let cipherText = { data: stringToUint8Array(plain) };
    let updateOutput = await globalCipher.update(cipherText);
    if (updateOutput && updateOutput.data) {
      result += uint8ArrayTohexString(updateOutput.data);
    }
    // doFinal
    let finalOutput = await globalCipher.doFinal(null);
    if (finalOutput && finalOutput.data) {
      result += uint8ArrayTohexString(finalOutput.data);
    }
    return result;
  }

  static async ohGenAesCbcDecryptWithIv(
    plain: string,
    workKey: string,
    iv: string
  ): Promise<string> {
    if (!plain || !workKey || !iv) {
      return plain;
    }
    let result = '';
    // 创建对称密钥生成器
    let symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    let keyDataBlob = { data: hexStringToUint8Array(workKey) };
    let sysKey = await symKeyGenerator.convertKey(keyDataBlob);

    // 生成加解密生成器
    let cipherAlgName = 'AES256|CBC|PKCS5';
    let params = { iv: { data: hexStringToUint8Array(iv) }, algName: 'IvParamsSpec' };

    // 创建Cipher对象
    let globalCipher = cryptoFramework.createCipher(cipherAlgName);

    // init
    await globalCipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, sysKey, params);
    // update  算法库不限定update的次数和每次加解密的数据量，需要业务验证大数据量情况下的性能
    let cipherText = { data: hexStringToUint8Array(plain) };
    let updateOutput = await globalCipher.update(cipherText);
    if (updateOutput && updateOutput.data) {
      result += uint8ArrayToString(updateOutput.data);
    }

    // doFinal
    let finalOutput = await globalCipher.doFinal(null);
    if (finalOutput && finalOutput.data) {
      result += uint8ArrayToString(finalOutput.data);
    }
    return result;
  }
}
