/**
 * @fileOverview Type determination tool
 */
export function isNumber(p: unknown): p is number {
  return typeof p === 'number' || p instanceof Number;
}

export function isFunction(p: unknown): p is Function {
  return typeof p === 'function';
}

export function isObject(p: unknown): p is { [key: string]: unknown } | null {
  return typeof p === 'object';
}

export function isDefined<T>(p: T | null | undefined): p is T {
  return p != null;
}

export function isJustDefined<T>(p: T | null | undefined): p is T | null {
  return p !== void 0;
}

export function isString(p: unknown): p is string {
  return typeof p === 'string' || p instanceof String;
}

export function isInteger(p: unknown): p is number {
  return isNumber(p) && Number.isInteger(p);
}
