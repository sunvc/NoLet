import { AGCError } from '@hw-agconnect/hmcore';
import { CONFIG_STORAGE_BUCKET_KEY } from './constants';

export enum AGCStorageErrorCode {
  UNKNOWN = 1230001,
  CANCELED,
  INVALID_CONFIG,
  INVALID_ARGUMENT,
  INVALID_ARGUMENT_COUNT,
  INVALID_OPERATION,
  INVALID_FORMAT,
  INVALID_URL,
  INVALID_ADDRESS,
  INVALID_DEFAULT_BUCKET,
  NO_DEFAULT_BUCKET,
  NO_DOWNLOAD_URL,
  CANNOT_SLICE_BLOB,
  SERVER_FILE_WRONG_SIZE
}

export class AGCStorageError extends AGCError {
  constructor(code: number, msg?: string) {
    super(code, msg ? msg : AGCStorageError.defaultErrorMsgDict[code]);
  }

  private static defaultErrorMsgDict = {
    [AGCStorageErrorCode.UNKNOWN]:
      'An unknown error occurred, please check the serverResponse information',
    [AGCStorageErrorCode.CANCELED]: 'The operation was cancelled.',
    [AGCStorageErrorCode.INVALID_CONFIG]:
      'Get CloudStorage configuration failed. Please check it again.',
    [AGCStorageErrorCode.INVALID_URL]: 'Invalid url',
    [AGCStorageErrorCode.INVALID_DEFAULT_BUCKET]: 'Invalid default bucket',
    [AGCStorageErrorCode.NO_DEFAULT_BUCKET]: `No default bucket found. Please set the ${CONFIG_STORAGE_BUCKET_KEY} property when initializing the configuration.`,
    [AGCStorageErrorCode.CANNOT_SLICE_BLOB]:
      'Failed to slice blob for upload. Please retry the upload.',
    [AGCStorageErrorCode.NO_DOWNLOAD_URL]: 'The given file does not have any download URLs.',
    [AGCStorageErrorCode.INVALID_ADDRESS]:
      'Can not find any valid urls, please check your SDK code copied from website again.',
    [AGCStorageErrorCode.SERVER_FILE_WRONG_SIZE]:
      'Server recorded incorrect upload file size, please retry the upload.'
  };
}
