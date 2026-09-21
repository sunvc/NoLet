import { UrlParams } from '../server/request/CloudStorageRequest';

export function makeUrl(urlPart: string): string {
  return `/v0${urlPart}`;
}

export function makeQueryString(params: UrlParams): string {
  let queryPart = '?';
  for (const key in params) {
    if (Object.prototype.hasOwnProperty.call(params, key)) {
      const nextPart = encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
      queryPart = queryPart + nextPart + '&';
    }
  }
  queryPart = queryPart.slice(0, -1);
  return queryPart;
}
