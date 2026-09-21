import { UploadResultImpl } from './uploadResultImpl';
import { StorageManagementImpl } from '../implementation/storageManagementImpl';
import { CSBlob } from './file';
import { MetadataComplete } from '../storage';
import { Location } from '../implementation/location';
import { AGCStorageError, AGCStorageErrorCode } from '../implementation/error';
import { INTERNAL_TASK_STATE, TaskState, taskStateFromInternalTaskState } from './taskenums';
import { validate } from '../utils/validator';
import { MultipartUploadRequest } from '../server/request/MultipartUploadRequest';
import { ResumableUploadStatusRequest } from '../server/request/ResumableUploadStatusRequest';
import { ResumableUploadStatus, resumableUploadChunkSize } from '../server/request/UploadUtils';
import { ContinueResumableUploadRequest } from '../server/request/ContinueResumableUploadRequest';
import { GetFileMetadataRequest } from '../server/request/GetFileMetadataRequest';
import { Logger } from '@hw-agconnect/hmcore';
import { StorageManagement, ServiceUploadResult, UploadTask } from '../interface/innerInterface';

export class UploadTaskImpl implements UploadTask {
  private storageManagement: StorageManagementImpl;
  private location_: Location;
  private blob_: CSBlob;
  private metadata_: MetadataComplete | null;
  private transferred_: number = 0;
  private needToFetchStatus_: boolean = false;
  private needToFetchMetadata_: boolean = false;
  private resumable_: boolean;
  private state_: INTERNAL_TASK_STATE;
  private error_: Error | null = null;
  private chunkMultiplier_: number = 1;
  private errorHandler_: (p1: AGCStorageError) => void;
  private metadataErrorHandler_: (p1: AGCStorageError) => void;
  private resolve_: ((p1: ServiceUploadResult) => void) | null = null;
  private reject_: ((p1: Error) => void) | null = null;
  private promise_: Promise<ServiceUploadResult>;
  private area_: string;
  private listenerMap = new Map();
  private progressType = 'progress';

  constructor(
    storageManagement: StorageManagement,
    location: Location,
    blob: CSBlob,
    metadata: MetadataComplete | null = null,
    area: string
  ) {
    this.storageManagement = storageManagement as StorageManagementImpl;
    this.location_ = location;
    this.blob_ = blob;
    this.metadata_ = metadata;
    this.resumable_ = this.shouldDoResumable_(this.blob_);
    this.state_ = INTERNAL_TASK_STATE.RUNNING;
    this.area_ = area;
    this.errorHandler_ = error => {
      this.chunkMultiplier_ = 1;
      this.error_ = error;
      this.transition_(INTERNAL_TASK_STATE.ERROR);
    };
    this.metadataErrorHandler_ = error => {
      if (error.code == AGCStorageErrorCode.CANCELED) {
        this.completeTransitions_();
      } else {
        this.error_ = error;
        this.transition_(INTERNAL_TASK_STATE.ERROR);
      }
    };
    this.promise_ = new Promise((resolve, reject) => {
      this.resolve_ = resolve;
      this.reject_ = reject;
      this.blob_.computeSha256().then(() => {
        this.start_();
      });
    });

    this.promise_.then(null, () => {});
  }

  private shouldDoResumable_(blob: CSBlob): boolean {
    return blob.size() > 100 * 1024;
  }

  private start_(): void {
    if (this.state_ !== INTERNAL_TASK_STATE.RUNNING) {
      return;
    }
    if (this.resumable_) {
      if (this.needToFetchStatus_) {
        this.fetchStatus_();
      } else {
        if (this.needToFetchMetadata_) {
          this.fetchMetadata_();
        } else {
          this.continueUpload_();
        }
      }
    } else {
      this.oneShotUpload_();
    }
  }

  private fetchStatus_(): void {
    const statusRequest = this.storageManagement.makeRequest(
      new ResumableUploadStatusRequest(
        this.storageManagement,
        this.location_,
        this.blob_,
        this.area_
      )
    );
    statusRequest.then(res => {
      res = res as ResumableUploadStatus;
      this.updateProgress_(res.current);
      this.needToFetchStatus_ = false;
      if (res.finalized) {
        this.needToFetchMetadata_ = true;
      }
      this.completeTransitions_();
    }, this.errorHandler_);
  }

  private continueUpload_(): void {
    const chunkSize = resumableUploadChunkSize * this.chunkMultiplier_;
    const status = new ResumableUploadStatus(this.transferred_, this.blob_.size());

    let status_: ResumableUploadStatus;
    let body: CSBlob | null;
    let bytesToUpload: number;
    try {
      if (status) {
        status_ = new ResumableUploadStatus(status.current, status.total);
      } else {
        status_ = new ResumableUploadStatus(0, this.blob_.size());
      }
      if (this.blob_.size() !== status_.total) {
        throw new AGCStorageError(AGCStorageErrorCode.SERVER_FILE_WRONG_SIZE);
      }
      const bytesLeft = status_.total - status_.current;
      bytesToUpload = bytesLeft;
      if (chunkSize > 0) {
        bytesToUpload = Math.min(bytesToUpload, chunkSize);
      }
      const startByte = status_.current;
      const endByte = startByte + bytesToUpload;
      body = this.blob_.slice(startByte, endByte);
      if (body === null) {
        throw new AGCStorageError(AGCStorageErrorCode.CANNOT_SLICE_BLOB);
      }
    } catch (e: any) {
      this.error_ = e;
      this.transition_(INTERNAL_TASK_STATE.ERROR);
      return;
    }
    const uploadRequest = this.storageManagement.makeRequest(
      new ContinueResumableUploadRequest(
        this.storageManagement,
        this.location_,
        this.blob_,
        chunkSize,
        this.area_,
        body.uploadData(),
        status,
        bytesToUpload,
        this.metadata_
      )
    );
    uploadRequest.then((newStatus: ResumableUploadStatus) => {
      this.updateProgress_(newStatus.current);
      if (newStatus.finalized) {
        this.metadata_ = newStatus.metadata;
        this.transition_(INTERNAL_TASK_STATE.SUCCESS);
      } else {
        this.completeTransitions_();
      }
    }, this.errorHandler_);
  }

  private increaseMultiplier_(): void {
    const currentSize = resumableUploadChunkSize * this.chunkMultiplier_;

    // Max chunk size is 32M.
    if (currentSize < 32 * 1024 * 1024) {
      this.chunkMultiplier_ *= 2;
    }
  }

  private fetchMetadata_(): void {
    const fetchMetadataRequest = this.storageManagement.makeRequest(
      new GetFileMetadataRequest(this.storageManagement, this.location_, this.area_)
    );
    fetchMetadataRequest.then(metadata => {
      this.metadata_ = metadata;
      this.transition_(INTERNAL_TASK_STATE.SUCCESS);
    }, this.metadataErrorHandler_);
  }

  private oneShotUpload_(): void {
    const multipartRequest = this.storageManagement.makeRequest(
      new MultipartUploadRequest(
        this.storageManagement,
        this.location_,
        this.blob_,
        this.area_,
        this.metadata_
      )
    );
    multipartRequest.then(metadata => {
      this.metadata_ = metadata;
      this.updateProgress_(this.blob_.size());
      this.transition_(INTERNAL_TASK_STATE.SUCCESS);
    }, this.errorHandler_);
  }

  private updateProgress_(transferred: number): void {
    const old = this.transferred_;
    this.transferred_ = transferred;

    if (this.transferred_ !== old) {
      this.notifyObservers_();
    }
  }

  private transition_(state: INTERNAL_TASK_STATE): void {
    if (this.state_ === state) {
      return;
    }
    switch (state) {
      case INTERNAL_TASK_STATE.CANCELING:
        this.state_ = state;
        break;
      case INTERNAL_TASK_STATE.PAUSING:
        this.state_ = state;
        break;
      case INTERNAL_TASK_STATE.RUNNING:
        const wasPaused = this.state_ === INTERNAL_TASK_STATE.PAUSED;
        this.state_ = state;
        if (wasPaused) {
          this.notifyObservers_();
          this.start_();
        }
        break;
      case INTERNAL_TASK_STATE.PAUSED:
        this.state_ = state;
        this.notifyObservers_();
        break;
      case INTERNAL_TASK_STATE.CANCELED:
        this.error_ = new AGCStorageError(AGCStorageErrorCode.CANCELED);
        this.state_ = state;
        this.notifyObservers_();
        break;
      case INTERNAL_TASK_STATE.ERROR:
        this.state_ = state;
        this.notifyObservers_();
        break;
      case INTERNAL_TASK_STATE.SUCCESS:
        this.state_ = state;
        this.notifyObservers_();
        break;
      default: // Ignore
    }
  }

  private completeTransitions_(): void {
    switch (this.state_) {
      case INTERNAL_TASK_STATE.PAUSING:
        this.transition_(INTERNAL_TASK_STATE.PAUSED);
        break;
      case INTERNAL_TASK_STATE.CANCELING:
        this.transition_(INTERNAL_TASK_STATE.CANCELED);
        break;
      case INTERNAL_TASK_STATE.RUNNING:
        this.start_();
        break;
      default:
        break;
    }
  }

  snapshot(): ServiceUploadResult {
    const state = taskStateFromInternalTaskState(this.state_);
    return new UploadResultImpl(this.transferred_, this.blob_.size(), state);
  }

  on(type: 'progress', callback: (uploadedSize: number, totalSize: number) => void): void {
    this.listenerMap.set(type, callback);
  }

  off(type: 'progress', callback: (uploadedSize: number, totalSize: number) => void): void {
    this.listenerMap.delete(type);
  }

  then<U>(
    onFulfilled?: ((value: ServiceUploadResult) => U | Promise<U>) | null,
    onRejected?: ((error: Error) => U | Promise<U>) | null
  ): Promise<U> {
    return this.promise_.then<U>(
      onFulfilled as (value: ServiceUploadResult) => U | Promise<U>,
      onRejected as ((error: unknown) => Promise<never>) | null
    );
  }

  catch<T>(onRejected: (reject: Error) => T | Promise<T>): Promise<T> {
    return this.then(null, onRejected);
  }

  private notifyObservers_(): void {
    this.finishPromise_();
    this.notifyObserver_();
  }

  private finishPromise_(): void {
    if (this.resolve_ !== null) {
      let trigger = true;
      switch (taskStateFromInternalTaskState(this.state_)) {
        case TaskState.SUCCESS:
          async(this.resolve_.bind(null, this.snapshot()))();
          break;
        case TaskState.CANCELED:
        case TaskState.ERROR:
          const toCall = this.reject_ as (p1: Error) => void;
          async(toCall.bind(null, this.error_ as Error))();
          break;
        default:
          trigger = false;
          break;
      }
      if (trigger) {
        this.reject_ = null;
        this.resolve_ = null;
      }
    }
  }

  private notifyObserver_(): void {
    const externalState = taskStateFromInternalTaskState(this.state_);
    switch (externalState) {
      case TaskState.RUNNING:
        if (this.listenerMap.get(this.progressType)) {
          this.listenerMap.get(this.progressType)(
            this.snapshot().bytesTransferred,
            this.snapshot().totalByteCount
          );
        }
        break;
      case TaskState.SUCCESS:
        if (this.listenerMap.get(this.progressType)) {
          this.listenerMap.get(this.progressType)(
            this.snapshot().bytesTransferred,
            this.snapshot().totalByteCount
          );
        }
        Logger.info('cloudstorage-task', 'upload success.');
        break;
      case TaskState.PAUSED:
      case TaskState.CANCELED:
      case TaskState.ERROR:
        Logger.error('cloudstorage-task', 'upload failed, reason:' + externalState);
        break;
      default:
        Logger.error('cloudstorage-task', 'upload failed, reason: unknown.');
    }
  }

  resume(): boolean {
    validate('resume', [], arguments);
    const resume =
      this.state_ === INTERNAL_TASK_STATE.PAUSED || this.state_ === INTERNAL_TASK_STATE.PAUSING;
    if (resume) {
      this.transition_(INTERNAL_TASK_STATE.RUNNING);
    }
    return resume;
  }

  pause(): boolean {
    validate('pause', [], arguments);
    const pause = this.state_ === INTERNAL_TASK_STATE.RUNNING;
    if (pause) {
      this.transition_(INTERNAL_TASK_STATE.PAUSING);
    }
    return pause;
  }

  cancel(): boolean {
    validate('cancel', [], arguments);
    const cancel =
      this.state_ === INTERNAL_TASK_STATE.RUNNING || this.state_ === INTERNAL_TASK_STATE.PAUSING;
    if (cancel) {
      this.transition_(INTERNAL_TASK_STATE.CANCELING);
    }
    return cancel;
  }
}

export function async(f: Function): Function {
  return (...args: unknown[]) => {
    Promise.resolve().then(() => f.apply(args));
  };
}
