import { Logger } from '@hw-agconnect/hmcore';
import { FileStorage } from '@hw-agconnect/hmcore';
import { getContext } from '@hw-agconnect/hmcore';
import { DefaultCrypto } from '@hw-agconnect/hmcore';

const TAG: string = 'StoredManager';

export class StoredManager {
  private FILE_PATH: string = 'agconnect';
  private DEFAULT_FILE_NAME = 'auth_aegis';
  private name: string;

  constructor(name: string) {
    this.name = name;
    Logger.info(TAG, 'constructor, name is ' + name);
  }

  public async saveToStorage(storeInfo: any | null): Promise<void> {
    let context = getContext();
    let fileName = this.DEFAULT_FILE_NAME + '_' + this.name;
    if (storeInfo == null) {
      Logger.info(TAG, 'clear storage user');
      await FileStorage.write(context, this.FILE_PATH, fileName, '');
      return Promise.resolve();
    }
    let userString: string = JSON.stringify(storeInfo);
    let crypto = await DefaultCrypto.get();
    await FileStorage.write(context, this.FILE_PATH, fileName, userString, crypto);
    return Promise.resolve();
  }

  public async loadFromStorage(): Promise<any | null> {
    let context = getContext();
    let fileName = this.DEFAULT_FILE_NAME + '_' + this.name;
    let crypto = await DefaultCrypto.get();
    let result = await FileStorage.read(context, this.FILE_PATH, fileName, crypto);
    if (!result) {
      return null;
    }
    try {
      let data = JSON.parse(result);
      return data;
    } catch (e) {
      Logger.error(TAG, 'user json parse error.');
      await FileStorage.write(context, this.FILE_PATH, fileName, '');
      return null;
    }
  }
}
