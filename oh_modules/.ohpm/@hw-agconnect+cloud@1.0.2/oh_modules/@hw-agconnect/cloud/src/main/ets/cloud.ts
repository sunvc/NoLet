import { Auth } from './auth/Auth';
import { Region } from '@hw-agconnect/hmcore';
import { Database, DatabaseConfig } from './database/Database';
import { FunctionOptions, FunctionResult } from './function/index';
import { LowCode } from './lowcode/index';
import { Storage, StorageOptions } from './storage/storage';

export interface Cloud {
  auth(): Auth;

  callFunction(options: FunctionOptions): Promise<FunctionResult>;

  database(config: DatabaseConfig): Database;

  storage(options?: StorageOptions): Storage;

  lowCode(): LowCode;

  getRegion(): Region;

  setRegion(region: Region);
}
