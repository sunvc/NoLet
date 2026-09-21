export interface ProgressEvent {
  loaded: number;
  total: number;
}

export interface UploadParam {
  localPath: string;
  cloudPath: string;
  onUploadProgress?: (p: ProgressEvent) => void;
}

export interface DownloadParam {
  localPath: string;
  cloudPath: string;
  onDownloadProgress?: (p: ProgressEvent) => void;
}

export interface TransResult {
  bytesTransferred: number;
  totalByteCount: number;
}

export interface ListParam {
  cloudPath?: string;
  maxResults?: number;
  pageMarker?: string;
}

export interface ListResult {
  dirList: string[];
  fileList: string[];
  pageMarker?: string;
}

export interface MetadataUpdatable {
  contentType?: string;
  cacheControl?: string;
  contentDisposition?: string;
  contentEncoding?: string;
  contentLanguage?: string;
  customMetadata?: Record<string, string>;
}

export interface MetadataComplete extends MetadataUpdatable {
  bucket: string;
  name: string;
  size: number;
  ctime: string;
  mtime: string;
  sha256Hash: string;
}

export interface UpdateMetaDataParam {
  cloudPath: string;
  metaData: MetadataUpdatable;
}

export interface StorageOptions {
  bucket?: string;
}

export interface Storage {
  upload(uploadParam: UploadParam): Promise<TransResult>;

  download(downloadParam: DownloadParam): Promise<TransResult>;

  getDownloadURL(cloudPath: string): Promise<string>;

  delete(cloudPath: string): Promise<void>;

  root(): Promise<string>;

  list(listParam?: ListParam): Promise<ListResult>;

  setMetaData(metaDataParam: UpdateMetaDataParam): Promise<MetadataComplete>;

  getMetaData(cloudPath: string): Promise<MetadataComplete>;
}
