import cryptoFramework from '@ohos.security.cryptoFramework';
import buffer from '@ohos.buffer';
import { Logger } from '../log/Logger';

const genRanHex = (size: any) =>
  [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');

/**
 * 要求鸿蒙SDK版本》=3.2.7.5
 */
export class AegisRandom {
  /**
   * ohos 加解密安全随机实现
   * @param randLen  随机数长度
   * @returns 已hex码返回
   */
  public static async generatedRandomHex(randLen: number): Promise<string> {
    try {
      let random = cryptoFramework.createRandom();
      let blob = await random.generateRandom(randLen);
      if (blob.data) {
        let buf = buffer.from(blob.data);
        if (buf && buf?.length == randLen) {
          return buf.toString('hex');
        }
      }
    } catch (error) {
      Logger.error(
        'AegisRandom',
        `generatedRandom error, code:${error?.code}, message:${error?.message}`
      );
    }
    return this.random(randLen);
  }

  /**
   * @deprecated
   */
  private static async random(randLen: number): Promise<string> {
    return Promise.resolve(genRanHex(randLen * 2));
  }
}
