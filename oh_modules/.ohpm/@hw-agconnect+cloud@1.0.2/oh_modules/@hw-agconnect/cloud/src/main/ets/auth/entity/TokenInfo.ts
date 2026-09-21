export class TokenInfo {
  private token: string;

  private validPeriod: number;

  /**
   * 构造方法，给定一些默认值，需要改变时，通过set方法设置
   */
  constructor() {
    this.token = '';
    this.validPeriod = 0;
  }

  getToken(): string {
    return this.token;
  }

  setToken(value: string) {
    this.token = value;
  }

  getValidPeriod(): number {
    return this.validPeriod;
  }

  setValidPeriod(value: number) {
    this.validPeriod = value;
  }
}
