import { TokenResult } from '../Auth';
export enum TokenState {
  SIGNED_IN, // 取得AGC授权,调用signIn取得授权
  TOKEN_UPDATED, // AGC Token更新
  TOKEN_INVALID, // AGC Token失效
  SIGNED_OUT // AGC注销
}

export class TokenImpl implements TokenResult {
  state: TokenState | undefined = undefined;
  expiration: number;
  tokenString: string;

  constructor(expiration: number, tokenString: string) {
    this.expiration = expiration;
    this.tokenString = tokenString;
  }

  getString(): string {
    return this.tokenString;
  }

  getExpirePeriod(): number {
    return this.expiration;
  }

  public getState(): TokenState | undefined {
    return this.state;
  }

  public getToken() {
    return this.tokenString;
  }
}
