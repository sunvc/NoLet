import { VerifyCodeResult } from '../Auth';

export class VerifyCodeResultImpl implements VerifyCodeResult {
  private shortestInterval: string;
  private validityPeriod: string;

  constructor(shortestInterval: string, validityPeriod: string) {
    this.shortestInterval = shortestInterval;
    this.validityPeriod = validityPeriod;
  }

  getShortestInterval(): string {
    return this.shortestInterval;
  }

  getValidityPeriod(): string {
    return this.validityPeriod;
  }
}
