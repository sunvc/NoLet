import { Token } from '../core';

export class CredentialInfo implements Token {
  expiration: number;
  tokenString: string;
  // 最后一次fetch时间
  lastRefreshTime: number;

  private TWO_MINUTES_EARLY: number = 2 * 60 * 1000;
  private ONE_HOUR: number = 60 * 60 * 1000;

  constructor(expiration: number, tokenString: string, lastRefreshTime: number) {
    this.expiration = expiration;
    this.tokenString = tokenString;
    this.lastRefreshTime = lastRefreshTime;
  }

  isValid(): boolean {
    let currentTime: number = new Date().getTime();
    let validTime = this.lastRefreshTime + this.expiration * 1000 - this.TWO_MINUTES_EARLY;
    return null != this.tokenString && currentTime <= validTime;
  }

  allowRefresh(): boolean {
    return new Date().getTime() - this.lastRefreshTime > this.ONE_HOUR;
  }
}
