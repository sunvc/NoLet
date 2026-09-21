import { BaseResponse } from '@hw-agconnect/hmcore';
import { LowCodeCommonResult } from '../index';

export class LowCodeCommonResultImpl<T> extends BaseResponse implements LowCodeCommonResult<T> {
  private responseBody: any = undefined;

  constructResponse(response: any): boolean {
    this.responseBody = response;
    return true;
  }

  getValue(): T | null {
    if (this.responseBody) {
      return this.responseBody as T;
    }
    return null;
  }
}
