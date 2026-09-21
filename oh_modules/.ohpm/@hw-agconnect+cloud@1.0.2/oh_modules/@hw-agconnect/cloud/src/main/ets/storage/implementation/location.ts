import { AGCStorageError, AGCStorageErrorCode } from './error';

export class Location {
  private path_: string;

  constructor(public readonly bucket: string, path: string) {
    this.path_ = path;
  }

  static makeFromUrl(url: string): Location {
    if (url == null || url.length == 0) {
      throw new AGCStorageError(AGCStorageErrorCode.INVALID_URL);
    }

    let location: Location | null = null;

    const bucketRegex = '([a-z0-9-]+)';
    const pathRegex = '(/(.*))?$';
    const hostRegex = '([a-z.\\-]+)';

    let bucket = '';
    let path = '';

    if (url.startsWith('https://') || url.startsWith('http://')) {
      let versionRegex = '(v[0-9]+)';
      let httpUrlRegex = new RegExp(
        `^https?://${hostRegex}/${versionRegex}/${bucketRegex}${pathRegex}`,
        'i'
      );
      const captures = httpUrlRegex.exec(url);
      if (captures) {
        bucket = captures[3];
        path = captures[5];
        if (!path) {
          path = '';
        }
        location = new Location(bucket, decodeURIComponent(path));
      }
    }
    if (url.startsWith('grs://')) {
      let grsUrlRegex = new RegExp(`^grs://${bucketRegex}${pathRegex}`);
      const captures = grsUrlRegex.exec(url);
      if (captures) {
        bucket = captures[1];
        path = captures[3];
        if (!path) {
          path = '';
        }
        if (path.charAt(path.length - 1) === '/') {
          path = path.slice(0, -1);
        }
        location = new Location(bucket, path);
      }
    }

    if (location == null) {
      throw new AGCStorageError(AGCStorageErrorCode.INVALID_URL);
    }
    return location;
  }

  static makeFromBucket(bucket: string): Location {
    let bucketLocation;
    try {
      bucketLocation = Location.makeFromUrl(bucket);
    } catch (e) {
      // While only input bucket name
      return new Location(bucket, '');
    }
    if (bucketLocation.path() === '') {
      return bucketLocation;
    } else {
      throw new AGCStorageError(AGCStorageErrorCode.INVALID_DEFAULT_BUCKET);
    }
  }

  path(): string {
    return this.path_;
  }

  isRoot(): boolean {
    return this.path_.length === 0;
  }

  fullUrl(): string {
    return '/' + encodeURIComponent(this.bucket) + '/' + encodeURIComponent(this.path_);
  }

  bucketUrl(): string {
    return '/' + encodeURIComponent(this.bucket);
  }
}
