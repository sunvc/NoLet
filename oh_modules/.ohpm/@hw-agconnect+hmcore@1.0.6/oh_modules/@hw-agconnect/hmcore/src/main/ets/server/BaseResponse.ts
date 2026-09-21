import { ConnectRet } from './ConnectRet';

export class BaseResponse {
  ret: ConnectRet = new ConnectRet();

  constructor() {}

  public isSuccess(): boolean {
    return this.ret != null && this.ret.getCode() == 0;
  }

  getRet(): ConnectRet {
    return this.ret;
  }

  setRet(value: ConnectRet) {
    this.ret = value;
  }

  constructResponse(response: any): boolean {
    return false;
  }
}
