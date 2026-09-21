import { AGCStorageError, AGCStorageErrorCode } from '../implementation/error';

/**
 * @enum {string}
 */
export type StringFormat = string;

export const StringFormat = {
  DATA_URL: 'data_url',
  BASE64: 'base64',
  BASE64URL: 'base64url',
  RAW: 'raw'
};

/**
 * @struct
 */
export class StringData {
  dataType: string | null;

  constructor(public data: Uint8Array, dataType?: string | null) {
    this.dataType = dataType || null;
  }
}

export function dataFromString(stringFormat: StringFormat, stringData: string): StringData {
  switch (stringFormat) {
    case StringFormat.RAW:
      return new StringData(utf8Bytes(stringData));
    case StringFormat.BASE64:
    case StringFormat.BASE64URL:
      return new StringData(base64Bytes(stringFormat, stringData));
    case StringFormat.DATA_URL:
      return new StringData(dataURLBytes(stringData), dataURLContentType(stringData));
    default:
  }

  throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
}

export function utf8Bytes(value: string): Uint8Array {
  const resultArray: number[] = [];
  for (let i = 0; i < value.length; i++) {
    let char = value.charCodeAt(i);
    if (char <= 127) {
      resultArray.push(char);
    } else {
      if (char <= 2047) {
        resultArray.push(192 | (char >> 6), 128 | (char & 63));
      } else {
        if ((char & 64512) === 55296) {
          const valid = i < value.length - 1 && (value.charCodeAt(i + 1) & 64512) === 56320;
          if (!valid) {
            resultArray.push(239, 191, 189);
          } else {
            const hi = char;
            const lo = value.charCodeAt(++i);
            char = 65536 | ((hi & 1023) << 10) | (lo & 1023);
            resultArray.push(
              240 | (char >> 18),
              128 | ((char >> 12) & 63),
              128 | ((char >> 6) & 63),
              128 | (char & 63)
            );
          }
        } else {
          if ((char & 64512) === 56320) {
            resultArray.push(239, 191, 189);
          } else {
            resultArray.push(224 | (char >> 12), 128 | ((char >> 6) & 63), 128 | (char & 63));
          }
        }
      }
    }
  }
  return new Uint8Array(resultArray);
}

export function percentEncodedBytes(value: string): Uint8Array {
  let decodedStr;
  try {
    decodedStr = decodeURIComponent(value);
  } catch (e) {
    throw new AGCStorageError(AGCStorageErrorCode.INVALID_FORMAT, 'Invalid data URL format.');
  }
  return utf8Bytes(decodedStr);
}

export function base64Bytes(format: StringFormat, value: string): Uint8Array {
  switch (format) {
    case StringFormat.BASE64: {
      const hasUnder = value.indexOf('_') !== -1;
      const hasMinus = value.indexOf('-') !== -1;

      if (hasUnder || hasMinus) {
        const invalidChar = hasUnder ? '_' : '-';
        throw new AGCStorageError(
          AGCStorageErrorCode.INVALID_FORMAT,
          `Invalid character "${invalidChar}" found. Make sure it is base64 encoded.`
        );
      }
      break;
    }
    case StringFormat.BASE64URL: {
      const hasSlash = value.indexOf('/') !== -1;
      const hasPlus = value.indexOf('+') !== -1;

      if (hasSlash || hasPlus) {
        const invalidChar = hasSlash ? '/' : '+';
        throw new AGCStorageError(
          AGCStorageErrorCode.INVALID_FORMAT,
          `Invalid character "${invalidChar}" found. Make sure it is base64 encoded.`
        );
      }
      value = value.replace(/_/g, '/').replace(/-/g, '+');
      break;
    }
    default:
  }
  let valueStr;
  try {
    valueStr = decodeBase64(value);
  } catch (e) {
    throw new AGCStorageError(AGCStorageErrorCode.INVALID_FORMAT, 'Invalid character found');
  }
  const array = new Uint8Array(valueStr.length);
  for (let i = 0; i < valueStr.length; i++) {
    array[i] = valueStr.charCodeAt(i);
  }
  return array;
}

class DataURLParts {
  base64: boolean = false;
  contentType: string | null = null;
  rest: string;

  constructor(url: string) {
    const urls = url.match(/^data:([^,]+)?,/);
    if (urls === null) {
      throw new AGCStorageError(
        AGCStorageErrorCode.INVALID_FORMAT,
        "DATA URL must be formatted 'data:[<mediatype>][;base64],<data>'"
      );
    }
    const middle = urls[1] || null;
    if (middle != null) {
      this.base64 = endsWith(middle, ';base64');
      this.contentType = this.base64
        ? middle.substring(0, middle.length - ';base64'.length)
        : middle;
    }
    this.rest = url.substring(url.indexOf(',') + 1);
  }
}

export function dataURLBytes(dataUrl: string): Uint8Array {
  const parts = new DataURLParts(dataUrl);
  if (parts.base64) {
    return base64Bytes(StringFormat.BASE64, parts.rest);
  } else {
    return percentEncodedBytes(parts.rest);
  }
}

export function dataURLContentType(dataUrl: string): string | null {
  const parts = new DataURLParts(dataUrl);
  return parts.contentType;
}

function endsWith(value: string, end: string): boolean {
  const longEnough = value.length >= end.length;
  if (!longEnough) {
    return false;
  }
  return value.substring(value.length - end.length) === end;
}

const base64Table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';

export function decodeBase64(value: string): string {
  let base1, base2, base3, base4, char1, char2, char3;
  let result = '';
  let i = 0;
  value = value.replace(/[^A-Za-z0-9\+\/\=]/g, '');
  while (i < value.length) {
    base1 = base64Table.indexOf(value.charAt(i++));
    base2 = base64Table.indexOf(value.charAt(i++));
    base3 = base64Table.indexOf(value.charAt(i++));
    base4 = base64Table.indexOf(value.charAt(i++));
    char1 = (base1 << 2) | (base2 >> 4);
    char2 = ((base2 & 15) << 4) | (base3 >> 2);
    char3 = ((base3 & 3) << 6) | base4;
    result = result + String.fromCharCode(char1);
    if (base3 != 64) {
      result = result + String.fromCharCode(char2);
    }
    if (base4 != 64) {
      result = result + String.fromCharCode(char3);
    }
  }
  return result;
}
