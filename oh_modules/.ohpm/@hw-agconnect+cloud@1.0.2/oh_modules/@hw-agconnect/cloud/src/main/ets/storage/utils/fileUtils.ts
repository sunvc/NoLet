import fs from '@ohos.file.fs';

export class FileUtil {
  static TAG: string = 'StorageFileUtil';

  static async readFile(filePath: string): Promise<Uint8Array> {
    let bufSize = 4096;
    let readSize = 0;
    let readLen = 0;
    let buf = new ArrayBuffer(bufSize);
    let resArray = new Uint8Array();

    let srcFile = await fs.open(filePath);
    while (true) {
      readLen = await fs.read(srcFile.fd, buf, { offset: readSize });
      if (readLen <= 0) {
        break;
      }
      let tempArray = new Uint8Array(resArray.length + readLen);
      tempArray.set(resArray, 0);
      tempArray.set(new Uint8Array(buf, 0, readLen), resArray.length);
      resArray = tempArray;
      readSize += readLen;
    }
    await fs.close(srcFile);
    return resArray;
  }
}
