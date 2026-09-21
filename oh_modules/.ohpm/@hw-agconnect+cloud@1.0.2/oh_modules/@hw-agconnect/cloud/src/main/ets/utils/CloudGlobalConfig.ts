import { Auth } from '../auth/Auth';
import { Storage } from '../storage/storage';

export type AuthService = () => Auth;
export type StorageService = (bucketName?: string) => Storage;

export type CloudGlobalConfig = {
  region: string;
  auth?: AuthService;
  storage?: StorageService;
};
