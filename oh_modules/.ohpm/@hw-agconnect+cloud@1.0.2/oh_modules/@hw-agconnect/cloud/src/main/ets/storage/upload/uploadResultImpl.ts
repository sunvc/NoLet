import { ServiceUploadResult } from '../interface/innerInterface';
import { TaskState } from './taskenums';

export class UploadResultImpl implements ServiceUploadResult {
  constructor(
    readonly bytesTransferred: number,
    readonly totalByteCount: number,
    readonly state: TaskState
  ) {}
}
