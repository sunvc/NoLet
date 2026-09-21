import fs from '@ohos.file.fs';
import { Logger } from '../log/Logger';
import { ICrypto } from '../crypto/ICrypto';

export class FileStorage {
  static async write(
    context: any,
    path: string,
    fileName: string,
    content: string,
    crypto?: ICrypto
  ): Promise<boolean> {
    if (!context) {
      Logger.info('FileStorage', 'write context error');
      return Promise.resolve(false);
    }
    try {
      let writeContent = content;
      if (crypto) {
        writeContent = await crypto.encrypt(content);
      }

      let filePath = context.filesDir + '/' + path;
      if (!(await fs.access(filePath))) {
        await fs.mkdir(filePath)
        Logger.info('FileStorage', 'create dir success');
      }
      let file = filePath + '/' + fileName;

      // 打开可读写文件，若文件存在则文件长度清0，即该文件内容会消失。若文件不存在则建立该文件。
      // 此接口不会自动创建文件夹
      let stream = await fs.createStream(file, 'w+');
      await stream.write(writeContent);
      await stream.close();
      Logger.info('FileStorage', 'stream.write success');
      return Promise.resolve(true);
    }catch (e) {
      Logger.error('FileStorage', 'stream.write error' + JSON.stringify(e));
      return Promise.resolve(false);
    }

  }

  /**
   * 读取文件
   *
   * @param context
   * @param path
   * @param fileName
   * @returns null:文件不存在
   */
  static async read(
    context: any,
    path: string,
    fileName: string,
    crypto?: ICrypto
  ): Promise<string | null> {
    if (!context) {
      Logger.info('FileStorage', 'read context error');
      return Promise.resolve(null);
    }
    let file = context.filesDir + '/' + path + '/' + fileName;
    if (!(await fs.access(file))) {
      Logger.info('FileStorage', 'read file not existed.');
      return Promise.resolve(null);
    }
    try {
      let result = await fs.readText(file);
      if (crypto) {
        result = await crypto.decrypt(result);
      }
      return Promise.resolve(result);
    }catch (e) {

      // 使用新的鸿蒙版本有极低的概率解密老的数据失败，如果解密失败返回null
      Logger.error('FileStorage', 'decrypt data error.' + JSON.stringify(e));
      return Promise.resolve(null);
    }
  }
}


