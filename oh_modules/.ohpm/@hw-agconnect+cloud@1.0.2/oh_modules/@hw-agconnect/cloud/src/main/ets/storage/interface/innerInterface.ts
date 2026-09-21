import { MetadataComplete, ProgressEvent, TransResult } from '../storage';
import { TaskState } from '../upload/taskenums';

export interface StorageReference {
  /**
   * 云端的存储实例名称
   */
  bucket(): string;

  /**
   * 云端的路径信息
   */
  path(): string;

  /**
   * 云端的文件名称
   */
  name(): string;

  root(): StorageReference | null;

  parent(): StorageReference | null;

  child(path: string): StorageReference;

  delete(): Promise<void>;

  list(options?: ListOptions): Promise<ListRefResult>;

  putData(data: Uint8Array | ArrayBuffer): UploadTask;

  getDownloadURL(): Promise<string>;

  download(localPath: string, progressCallback: (p: ProgressEvent) => void): Promise<TransResult>;

  getMetaData(): Promise<MetadataComplete>;

  setMetaData(metaData: MetadataComplete): Promise<MetadataComplete>;

  toString(): string;
}

export interface ListOptions {
  maxResults?: number;
  pageMarker?: string;
}

export interface ListRefResult {
  dirList: StorageReference[];
  fileList: StorageReference[];
  pageMarker?: string | null;
}

export interface UploadTask {
  on(type: string, callback: (uploadedSize: number, totalSize: number) => void): void;

  cancel(): boolean;

  then<T>(onfulfilled?: (value: ServiceUploadResult) => T): Promise<T>;

  catch(onRejected: (a: Error) => any): Promise<any>;
}

export interface ServiceUploadResult {
  bytesTransferred: number;
  state: TaskState;
  totalByteCount: number;
}

export interface StorageManagement {
  storageReference(path?: string): Promise<StorageReference>;
}

export interface ServiceMetadata {
  bucket: string | undefined;
  name: string | undefined;
  size: number | undefined;
  createTime: string | undefined;
  updateTime: string | undefined;
  sha256: string | undefined;
  cacheControl: string | undefined;
  contentDisposition: string | undefined;
  contentEncoding: string | undefined;
  contentLanguage: string | undefined;
  contentType: string | undefined;
  metadata: { [key: string]: string } | undefined;
}
