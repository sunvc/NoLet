export class ConnectRet {
  private code: number;

  private msg: string;

  constructor(code: number = 0, msg: string = '') {
    this.code = code;
    this.msg = msg;
  }

  getCode(): number {
    return this.code;
  }

  setCode(value: number) {
    this.code = value;
  }

  getMsg(): string {
    return this.msg;
  }

  setMsg(value: string) {
    this.msg = value;
  }
}
