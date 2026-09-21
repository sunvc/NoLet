export class AGCError extends Error {
  code: number;
  message: string;

  constructor(code: number, message: string) {
    super();
    this.code = code;
    this.message = message;
    (this as any).__proto__ = AGCError.prototype;
  }
}
