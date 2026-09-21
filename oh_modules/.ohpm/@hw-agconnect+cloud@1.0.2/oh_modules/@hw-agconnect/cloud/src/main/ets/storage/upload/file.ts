import { StringFormat, dataFromString } from './string';
import * as type from '../utils/type';
import { Logger, sha256 } from '@hw-agconnect/hmcore';

const TAG = 'CSBlob';

export class CSBlob {
  private data_!: Uint8Array;
  private size_: number;
  private type_: string;
  private sha256_: string = '';

  constructor(blob: Uint8Array | ArrayBuffer, elideCopy?: boolean) {
    let size: number = 0;
    let blobType: string = '';
    if (blob instanceof ArrayBuffer) {
      if (elideCopy) {
        this.data_ = new Uint8Array(blob);
      } else {
        this.data_ = new Uint8Array(blob.byteLength);
        this.data_.set(new Uint8Array(blob));
      }
      size = this.data_.length;
    } else {
      if (elideCopy) {
        this.data_ = blob as Uint8Array;
      } else {
        this.data_ = new Uint8Array(blob.length);
        this.data_.set(blob as Uint8Array);
      }
      size = blob.length;
    }
    this.size_ = size;
    this.type_ = blobType;
  }

  async computeSha256(): Promise<void> {
    try {
      let data = this.data_ as Uint8Array;
      this.sha256_ = await sha256(data);
      Logger.info(TAG, 'CryptoJS hash sha256 success.');
    } catch (e) {
      Logger.error(TAG, 'CryptoJS sha256 error' + e?.message);
    }
  }

  sha256(): string {
    return this.sha256_;
  }

  size(): number {
    return this.size_;
  }

  type(): string {
    return this.type_;
  }

  slice(startByte: number, endByte: number): CSBlob | null {
    const slice = new Uint8Array((this.data_ as Uint8Array).buffer, startByte, endByte - startByte);
    return new CSBlob(slice, false);
  }

  static getBlob(...args: Array<string | CSBlob>): CSBlob | null {
    const uint8Arrays: Uint8Array[] = args.map((val: string | CSBlob): Uint8Array => {
      if (type.isString(val)) {
        return dataFromString(StringFormat.RAW, val as string).data;
      } else {
        return (val as CSBlob).data_ as Uint8Array;
      }
    });
    let finalLen = 0;
    uint8Arrays.forEach((array: Uint8Array): void => {
      finalLen += array.byteLength;
    });
    const mergedArray = new Uint8Array(finalLen);
    let index = 0;
    uint8Arrays.forEach((array: Uint8Array) => {
      for (let i = 0; i < array.length; i++) {
        mergedArray[index++] = array[i];
      }
    });
    return new CSBlob(mergedArray, true);
  }

  uploadData(): Uint8Array {
    return this.data_;
  }
}
