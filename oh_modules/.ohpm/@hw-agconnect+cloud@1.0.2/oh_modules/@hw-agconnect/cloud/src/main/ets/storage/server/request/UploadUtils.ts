import { MetadataComplete } from '../../storage';
import { CSBlob } from '../../upload/file';
import { Location } from '../../implementation/location';
import * as MetadataUtils from './MetaDataUtils';
import { AGCStorageError, AGCStorageErrorCode } from '../../implementation/error';

export const resumableUploadChunkSize: number = 100 * 1024;

export class ResumableUploadStatus {
  metadata: MetadataComplete | null;
  finalized: boolean;

  constructor(
    public current: number,
    public total: number,
    finalized?: boolean,
    metadata?: MetadataComplete | null
  ) {
    this.metadata = metadata || null;
    this.finalized = !!finalized;
  }
}

export function determineContentType_(
  metadata: MetadataComplete | null,
  blob: CSBlob | null
): string {
  return (
    (metadata && metadata['contentType']) || (blob && blob.type()) || 'application/octet-stream'
  );
}

export function metadataForUpload_(
  blob: CSBlob,
  location: Location,
  metadata?: MetadataComplete | null
): MetadataComplete {
  const metadataClone = { ...metadata };
  metadataClone['metadata'] = MetadataUtils.parseMetadata(metadataClone);
  metadataClone['size'] = blob.size();
  if (!metadataClone['contentType']) {
    metadataClone['contentType'] = determineContentType_(null, blob);
  }
  return metadataClone;
}

export function checkResumeHeader_(res: any, allowed?: string[]): string {
  let status: string | null = null;
  try {
    if (res) {
      status = res.uploadStatus;
    }
  } catch (e) {
    throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
  }
  const allowedStatus = allowed || ['active'];
  if (!status || allowedStatus.indexOf(status) == -1) {
    throw new AGCStorageError(AGCStorageErrorCode.UNKNOWN);
  }
  return status as string;
}
