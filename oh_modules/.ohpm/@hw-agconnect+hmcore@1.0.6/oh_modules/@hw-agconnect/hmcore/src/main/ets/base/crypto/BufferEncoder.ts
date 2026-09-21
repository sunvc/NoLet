interface UnicodeOk {
  unicode?: number
  ok: boolean
}

export class BufferEncoder {
  buffer: number[];
  private readOffset: number;

  constructor() {
    this.buffer = [];
    this.readOffset = 0;
  }

  pushUint8(value: number): void {
    if (value > 255) {
      throw Error("value need <= 255");
    }
    this.buffer.push(value);
  }

  pushUnicodeWithUtf8(value: number): void {
    if (value <= 0x7F) {
      this.pushUint8(value);
    } else if (value <= 0xFF) {
      this.pushUint8((value >> 6) | 0xC0);
      this.pushUint8((value & 0x3F) | 0x80);
    } else if (value <= 0xFFFF) {
      this.pushUint8((value >> 12) | 0xE0);
      this.pushUint8(((value >> 6) & 0x3F) | 0x80);
      this.pushUint8((value & 0x3F) | 0x80);
    } else if (value <= 0x1FFFFF) {
      this.pushUint8((value >> 18) | 0xF0);
      this.pushUint8(((value >> 12) & 0x3F) | 0x80);
      this.pushUint8(((value >> 6) & 0x3F) | 0x80);
      this.pushUint8((value & 0x3F) | 0x80);
    } else if (value <= 0x3FFFFFF) {
      this.pushUint8((value >> 24) | 0xF8);
      this.pushUint8(((value >> 18) & 0x3F) | 0x80);
      this.pushUint8(((value >> 12) & 0x3F) | 0x80);
      this.pushUint8(((value >> 6) & 0x3F) | 0x80);
      this.pushUint8((value & 0x3F) | 0x80);
    } else {
      this.pushUint8((value >> 30) & 0x1 | 0xFC);
      this.pushUint8(((value >> 24) & 0x3F) | 0x80);
      this.pushUint8(((value >> 18) & 0x3F) | 0x80);
      this.pushUint8(((value >> 12) & 0x3F) | 0x80);
      this.pushUint8(((value >> 6) & 0x3F) | 0x80);
      this.pushUint8((value & 0x3F) | 0x80);
    }
  }

  parseUnicodeFromUtf16(ch1: number, ch2: number): UnicodeOk {
    if ((ch1 & 0xFC00) === 0xD800 && (ch2 & 0xFC00) === 0xDC00) {
      return { unicode: (((ch1 & 0x3FF) << 10) | (ch2 & 0x3FF)) + 0x10000, ok: true }
    }
    return { ok: false }
  }

  pushStringWithUtf8(value: string): number {
    let oldLen = this.buffer.length;
    for (let i = 0; i < value.length; i++) {
      let ch1 = value.charCodeAt(i);
      if (ch1 < 128)
        this.pushUnicodeWithUtf8(ch1);
      else if (ch1 < 2048) {
        this.pushUnicodeWithUtf8(ch1);
      } else {
        let ch2 = value.charCodeAt(i + 1);
        let unicodeOk = this.parseUnicodeFromUtf16(ch1, ch2);
        if (unicodeOk.ok) {
          this.pushUnicodeWithUtf8(unicodeOk.unicode);
          i++;
        } else {
          this.pushUnicodeWithUtf8(ch1);
        }
      }
    }
    return this.buffer.length - oldLen;
  }

  toUint8Array(len?: number): Uint8Array {
    len = len || this.buffer.length;
    return new Uint8Array(this.buffer.slice(this.readOffset, this.readOffset + len));
  }
}