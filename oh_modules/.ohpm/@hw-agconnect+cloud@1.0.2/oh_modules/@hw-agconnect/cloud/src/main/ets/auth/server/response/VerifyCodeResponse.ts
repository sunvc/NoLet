import { BaseResponse } from '@hw-agconnect/hmcore';

export class VerifyCodeResponse extends BaseResponse {
  shortestInterval: string = '';
  validityPeriod: string = '';
}
