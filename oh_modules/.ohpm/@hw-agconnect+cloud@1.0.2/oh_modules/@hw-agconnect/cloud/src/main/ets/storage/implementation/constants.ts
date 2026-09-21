/**
 * The key in agconnect config json for the storage bucket.
 */
export const CONFIG_STORAGE_BUCKET_KEY = 'default_storage';

/**
 * 2 minutes
 *
 * The timeout for all operations except upload.
 */
export const DEFAULT_MAX_REQUEST_TIMEOUT = 2 * 60 * 1000;

/**
 * 10 minutes
 *
 * The timeout for upload.
 */
export const DEFAULT_MAX_UPLOAD_TIMEOUT = 10 * 60 * 1000;

/**
 * 3 times
 *
 * Request Retry Times
 */
export const DEFAULT_MAX_RETRY_TIMES = 3;

/**
 * This is the value of Number.MIN_SAFE_INTEGER, which is not well supported
 * enough for us to use it directly.
 */
export const MIN_SAFE_INTEGER = -9007199254740991;

/**
 * 1GB
 *
 * The size for max upload data size once
 */
export const MAX_UPLOAD_SIZE_ONCE = 1024 * 1024 * 1024;
