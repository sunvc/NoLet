/**
 * Note that it will return null when path is already root.
 * @return parent path
 */
export function parent(path: string): string | null {
  if (path.length === 0) {
    return null;
  }
  const pathWithoutTrailingSlash = path.replace(/\/$/, '');
  const index = pathWithoutTrailingSlash.lastIndexOf('/');
  if (index === -1) {
    return '';
  }
  return pathWithoutTrailingSlash.slice(0, index) + '/';
}

/**
 *
 * @param path path
 * @param childPath childPath
 * @return {string} path without trailing slash
 */
export function child(path: string, childPath: string): string {
  if (!childPath || childPath.length === 0) {
    return path;
  }
  let canonicalChildPath = childPath
    .split('/')
    .filter(component => component.length > 0)
    .join('/');
  if (childPath.endsWith('/')) {
    canonicalChildPath += '/';
  }
  if (path.length === 0) {
    return canonicalChildPath;
  } else {
    return path + canonicalChildPath;
  }
}

/**
 *
 * @param path path
 * @return {string} path without trailing slash
 */
export function lastComponent(path: string): string {
  const index = path.lastIndexOf('/', path.length - 2);
  if (index === -1) {
    return path;
  } else {
    return path.slice(index + 1);
  }
}
