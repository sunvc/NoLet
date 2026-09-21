import { getRegion, Region } from '@hw-agconnect/hmcore';
import { Auth } from './auth/Auth';
import { Cloud } from './cloud';
import { AuthImpl } from './auth/AuthImpl';
import { DatabaseImpl } from './database/DatabaseImpl';
import { Database, DatabaseConfig } from './database/Database';
import { FunctionOptions, FunctionResult } from './function';
import { callFunction } from './function/server/FunctionBackend';
import { Storage, StorageOptions } from './storage/storage';
import { StorageImpl } from './storage/implementation/storageImpl';
import { LowCode } from './lowcode';
import { LowCodeImpl } from './lowcode/impl/LowCodeImpl';

class hmCloud implements Cloud {
  private region: Region;
  private instanceMap = new Map<string, any>();

  getRegion(): Region {
    if (!this.region) {
      return getRegion();
    }
    return this.region;
  }

  setRegion(region: Region) {
    if (this.getRegion() != region) {
      this.region = region;
      this.instanceMap.clear();
    }
  }

  auth(): Auth {
    return this.getInstance('auth', () => {
      return new AuthImpl(this.getRegion());
    });
  }

  database(config: DatabaseConfig): Database {
    return new DatabaseImpl(this.getRegion(), config);
  }

  callFunction(options: FunctionOptions): Promise<FunctionResult> {
    return callFunction(options, {
      region: this.getRegion(),
      auth: () => {
        return this.auth();
      }
    });
  }

  storage(options?: StorageOptions): Storage {
    return new StorageImpl(this.getRegion(), options);
  }

  lowCode(): LowCode {
    return this.getInstance('lowcode', () => {
      return new LowCodeImpl({
        region: this.getRegion(),
        auth: () => {
          return this.auth();
        },
        storage: (bucketName: string) => {
          return this.storage({
            bucket: bucketName
          });
        }
      });
    });
  }

  getInstance<T>(key: string, createInstance: () => T): T {
    if (this.instanceMap.has(key)) {
      return this.instanceMap.get(key);
    }
    let instance = createInstance();
    this.instanceMap.set(key, instance);
    return instance;
  }
}

export default new hmCloud();
