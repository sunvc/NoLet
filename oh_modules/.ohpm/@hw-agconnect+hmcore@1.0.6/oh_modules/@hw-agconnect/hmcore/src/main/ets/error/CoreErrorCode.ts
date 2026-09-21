import { AGCError } from './AGCError';

export enum CoreErrorCode {
  INIT_ERROR = 1100001,
  JSON_FILE_ERROR = 1100002,
  DATASTORE_ERROR = 1100003
}

export function error(code: CoreErrorCode, message: string) {
  return new AGCError(code, message);
}
