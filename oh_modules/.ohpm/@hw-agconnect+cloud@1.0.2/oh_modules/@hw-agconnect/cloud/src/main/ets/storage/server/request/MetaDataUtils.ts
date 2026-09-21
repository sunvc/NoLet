import { MetadataComplete } from '../../storage';
import { ServiceMetadata } from '../../interface/innerInterface';

/**
 *
 * @param text text
 * @return Metadata
 */
export function parseResponse(res: any): MetadataComplete | null {
  if (res === null) {
    return null;
  }
  const serviceMetadata = res as unknown as ServiceMetadata;
  const metadata: MetadataComplete = {
    bucket: serviceMetadata.bucket,
    name: serviceMetadata.name,
    size: serviceMetadata.size,
    ctime: serviceMetadata.createTime,
    mtime: serviceMetadata.updateTime,
    contentLanguage: serviceMetadata.contentLanguage,
    contentEncoding: serviceMetadata.contentEncoding,
    contentDisposition: serviceMetadata.contentDisposition,
    contentType: serviceMetadata.contentType,
    cacheControl: serviceMetadata.cacheControl,
    customMetadata: serviceMetadata.metadata,
    sha256Hash: serviceMetadata.sha256
  };
  return metadata;
}

/**
 *
 * @param metadata Metadata
 * @return any
 */
export function parseMetadata(metadata: MetadataComplete): any | null {
  let requestMetadata: any = {};
  if (metadata.cacheControl) {
    requestMetadata['X-Agc-Cache-Control'] = metadata.cacheControl;
  }
  if (metadata.contentDisposition) {
    requestMetadata['X-Agc-Content-Disposition'] = metadata.contentDisposition;
  }
  if (metadata.contentEncoding) {
    requestMetadata['X-Agc-Content-Encoding'] = metadata.contentEncoding;
  }
  if (metadata.contentLanguage) {
    requestMetadata['X-Agc-Content-Language'] = metadata.contentLanguage;
  }
  if (metadata.contentType) {
    requestMetadata['X-Agc-Content-Type'] = metadata.contentType;
  }
  if (metadata.sha256Hash) {
    requestMetadata['X-Agc-Sha256'] = metadata.sha256Hash;
  }
  if (metadata.customMetadata) {
    for (const key in metadata.customMetadata) {
      if (metadata.customMetadata[key]) {
        const name = 'X-Agc-meta-' + key;
        requestMetadata[name] = metadata.customMetadata[key];
      }
    }
  }
  return requestMetadata;
}
