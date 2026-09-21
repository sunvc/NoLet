import { BaseResponse, ConnectRet } from '@hw-agconnect/hmcore';
import { FunctionResult } from '../index';

export class FunctionResponse extends BaseResponse implements FunctionResult {
  private responseBody: any = undefined;

  constructor(response: any) {
    super();
    this.setRet(new ConnectRet(0, 'OK'));
    let responseBody = undefined;
    try {
      responseBody = JSON.parse(response);
    } catch (err) {
      responseBody = response;
    }
    this.responseBody = responseBody;
  }

  getValue(): any {
    if (this.responseBody) {
      return this.responseBody;
    }
    return null;
  }
}
