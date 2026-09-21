import { ErrorCode } from '../../utils/ErrorCode';

export enum EncryptionKeyStatus {
  DEFAULT = 0,
  NORMAL = 1,
  UPDATING = 2,
  INTERRUPT = 3
}

export class EncryptInfo {
  private firstSaltValue_?: Uint8Array;

  private secondSaltValue_?: Uint8Array;

  private rootKeyToken_?: Uint8Array;

  private dataKeyCipherText_?: Uint8Array;

  private oldDataKeyCipherText_?: Uint8Array;

  private keyStatus_ = EncryptionKeyStatus.DEFAULT;

  private keyVersion_ = 0;

  get firstSaltValue(): Uint8Array | undefined {
    return this.firstSaltValue_;
  }

  set firstSaltValue(value: Uint8Array | undefined) {
    this.firstSaltValue_ = value;
  }

  get secondSaltValue(): Uint8Array | undefined {
    return this.secondSaltValue_;
  }

  set secondSaltValue(value: Uint8Array | undefined) {
    this.secondSaltValue_ = value;
  }

  get rootKeyToken(): Uint8Array | undefined {
    return this.rootKeyToken_;
  }

  set rootKeyToken(value: Uint8Array | undefined) {
    this.rootKeyToken_ = value;
  }

  get dataKeyCipherText(): Uint8Array | undefined {
    return this.dataKeyCipherText_;
  }

  set dataKeyCipherText(value: Uint8Array | undefined) {
    this.dataKeyCipherText_ = value;
  }

  get oldDataKeyCipherText(): Uint8Array | undefined {
    return this.oldDataKeyCipherText_;
  }

  set oldDataKeyCipherText(value: Uint8Array | undefined) {
    this.oldDataKeyCipherText_ = value;
  }

  get keyStatus(): number {
    return this.keyStatus_;
  }

  set keyStatus(status: number) {
    this.keyStatus_ = status;
  }

  get keyVersion(): number {
    return this.keyVersion_;
  }

  set keyVersion(version: number) {
    this.keyVersion_ = version;
  }

  clear() {
    this.firstSaltValue_?.set([], 0);
    this.secondSaltValue_?.set([], 0);
    this.rootKeyToken_?.set([], 0);
    this.dataKeyCipherText_?.set([], 0);
    this.oldDataKeyCipherText_?.set([], 0);
  }
}

export class EncryptResult {
  private encryptInfo_: EncryptInfo[] = [];

  private resultCode_: ErrorCode = ErrorCode.OK;

  constructor(resultCode: ErrorCode, encryptInfo: EncryptInfo[]) {
    this.resultCode_ = resultCode;
    this.encryptInfo_ = encryptInfo;
  }

  get resultCode(): ErrorCode {
    return this.resultCode_;
  }

  get encryptInfo(): EncryptInfo[] {
    return this.encryptInfo_;
  }
}
