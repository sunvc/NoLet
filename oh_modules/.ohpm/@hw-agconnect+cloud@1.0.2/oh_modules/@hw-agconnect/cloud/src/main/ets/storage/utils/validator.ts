import * as type from './type';
import { StringFormat } from '../upload/string';
import { MAX_UPLOAD_SIZE_ONCE } from '../implementation/constants';
import { AGCStorageError, AGCStorageErrorCode } from '../implementation/error';

export function validate(name: string, argSpec: ArgSpec[], iArguments: IArguments): void {
  let minArgs = argSpec.length;
  const maxArgs = argSpec.length;
  for (let i = 0; i < argSpec.length; i++) {
    if (argSpec[i].optional) {
      minArgs = i;
      break;
    }
  }
  const argsLength = minArgs <= iArguments.length && iArguments.length <= maxArgs;
  if (!argsLength) {
    throw new AGCStorageError(
      AGCStorageErrorCode.INVALID_ARGUMENT_COUNT,
      `Invalid argument count in ${name}`
    );
  }
  for (let i = 0; i < iArguments.length; i++) {
    try {
      argSpec[i].validator(iArguments[i]);
    } catch (e: any) {
      throw new AGCStorageError(
        AGCStorageErrorCode.INVALID_ARGUMENT,
        `Invalid argument in  ${name} at index:${i} , message:${e}`
      );
    }
  }
}

export class ArgSpec {
  validator: (p1: unknown) => void;
  optional: boolean;

  constructor(validator: (p1: unknown) => void, optional?: boolean) {
    const self = this;
    this.validator = function (p: unknown) {
      if (self.optional && !type.isJustDefined(p)) {
        return;
      }
      validator(p);
    };
    this.optional = !!optional;
  }
}

export function and_(v1: (p1: unknown) => void, v2: (p1: unknown) => void): (p1: unknown) => void {
  return function (p) {
    v1(p);
    v2(p);
  };
}

export function stringSpec(validator?: (p1: unknown) => void | null, optional?: boolean): ArgSpec {
  function stringValidator(p: unknown): void {
    if (!type.isString(p)) {
      throw 'Expected string.';
    }
  }

  let chainedValidator;
  if (validator) {
    chainedValidator = and_(stringValidator, validator);
  } else {
    chainedValidator = stringValidator;
  }
  return new ArgSpec(chainedValidator, optional);
}

export function pathLengthSpec(
  validator?: (p1: unknown) => void | null,
  optional?: boolean
): ArgSpec {
  function pathLengthValidator(p: unknown): void {
    if (!type.isString(p)) {
      throw 'Expected string.';
    }
    if (p.length > 1024) {
      throw 'Path length should not exceed 1024.';
    }
  }

  let chainedValidator;
  if (validator) {
    chainedValidator = and_(pathLengthValidator, validator);
  } else {
    chainedValidator = pathLengthValidator;
  }
  return new ArgSpec(chainedValidator, optional);
}

export function uploadDataSpec(): ArgSpec {
  function validator(data: unknown): void {
    const valid = data instanceof Uint8Array || data instanceof ArrayBuffer;
    if (!valid) {
      throw 'Expected Blob or File.';
    } else if ((data as any).byteLength == 0) {
      //note:ohos does not support empty body in put/post
      throw 'Expected data not empty.';
    } else if ((data as any).byteLength > MAX_UPLOAD_SIZE_ONCE) {
      throw 'Expected data not exceeding 1GB once.';
    }
  }

  return new ArgSpec(validator);
}

export function metadataSpec(optional?: boolean): ArgSpec {
  return new ArgSpec(metadataValidator, optional);
}

export function listOptionSpec(optional?: boolean): ArgSpec {
  return new ArgSpec(listOptionsValidator, optional);
}

export function nonNegativeNumberSpec(): ArgSpec {
  function validator(p: unknown): void {
    const valid = type.isNumber(p) && p >= 0;
    if (!valid) {
      throw 'Expected a number 0 or greater.';
    }
  }

  return new ArgSpec(validator);
}

export function looseObjectSpec(
  validator?: ((p1: unknown) => void) | null,
  optional?: boolean
): ArgSpec {
  function isLooseObjectValidator(p: unknown): void {
    const isLooseObject = p === null || (type.isDefined(p) && p instanceof Object);
    if (!isLooseObject) {
      throw 'Expected an Object.';
    }
    if (validator !== undefined && validator !== null) {
      validator(p);
    }
  }

  return new ArgSpec(isLooseObjectValidator, optional);
}

export function nullFunctionSpec(optional?: boolean): ArgSpec {
  function validator(p: unknown): void {
    const valid = p === null || type.isFunction(p);
    if (!valid) {
      throw 'Expected a Function.';
    }
  }

  return new ArgSpec(validator, optional);
}

export function forbiddenSymbol(string: unknown): void {
  if (typeof string !== 'string') {
    throw 'Expected string.';
  }
  let str = string as string;
  for (let i = 0; i < str.length; i++) {
    if ('#*:?\'"<>|[]'.indexOf(str[i]) !== -1) {
      throw 'Unexpected symbol: # * : ? \' " < > | [ ] \r \n';
    }
  }
  if (str.indexOf('\r') !== -1 || str.indexOf('\n') !== -1) {
    throw 'Unexpected symbol: # * : ? \' " < > | [ ] \r \n';
  }
}

const MAX_RESULTS_KEY = 'maxResults';
const MAX_MAX_RESULTS = 1000;
const PAGE_MARKER_KEY = 'pageMarker';

export function listOptionsValidator(p: unknown): void {
  if (!type.isObject(p) || !p) {
    throw 'Expected ListOptions object.';
  }
  for (const key in p) {
    if (key === MAX_RESULTS_KEY) {
      if (!type.isInteger(p[MAX_RESULTS_KEY]) || (p[MAX_RESULTS_KEY] as number) <= 0) {
        throw 'Expected maxResults to be a positive number.';
      }
      if ((p[MAX_RESULTS_KEY] as number) > 1000) {
        throw `Expected maxResults to be less than or equal to ${MAX_MAX_RESULTS}.`;
      }
    } else if (key === PAGE_MARKER_KEY) {
      if (p[PAGE_MARKER_KEY] && !type.isString(p[PAGE_MARKER_KEY])) {
        throw 'Expected pageMarker to be string.';
      }
    } else {
      throw 'Unknown option: ' + key;
    }
  }
}

export function metadataValidator(p: unknown): void {
  if (!type.isObject(p) || !p) {
    throw 'Expected Metadata object.';
  }
}

export function formatValidator(stringFormat: unknown): void {
  switch (stringFormat) {
    case StringFormat.DATA_URL:
    case StringFormat.BASE64:
    case StringFormat.BASE64URL:
    case StringFormat.RAW:
      return;
    default:
      throw (
        'Expected one of the following types: [' +
        StringFormat.RAW +
        ', ' +
        StringFormat.BASE64 +
        ', ' +
        StringFormat.BASE64URL +
        ', ' +
        StringFormat.DATA_URL +
        '].'
      );
  }
}

export function validatorArea(param: unknown) {
  if (typeof param !== 'string') {
    throw 'Expected a string';
  }
  const areas = ['CN', 'DE', 'RU', 'SG'];
  if (areas.indexOf(param as string) === -1) {
    throw 'Area must one of CN, DE, RU, SG.';
  }
}
