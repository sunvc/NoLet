import hilog from '@ohos.hilog';

export const AGC_DOMAIN = 0x888f;

export enum LogLevel {
  DEBUG = 3,
  INFO = 4,
  WARN = 5,
  ERROR = 6,
  FATAL = 7
}

export class Logger {
  static debug(tag: string, format: string, ...args: any[]): void {
    hilog.debug(AGC_DOMAIN, Logger.prefixTag(tag), format, args);
  }

  static info(tag: string, format: string, ...args: any[]): void {
    hilog.info(AGC_DOMAIN, Logger.prefixTag(tag), format, args);
  }

  static warn(tag: string, format: string, ...args: any[]): void {
    hilog.warn(AGC_DOMAIN, Logger.prefixTag(tag), format, args);
  }

  static error(tag: string, format: string, ...args: any[]): void {
    hilog.error(AGC_DOMAIN, Logger.prefixTag(tag), format, args);
  }

  static fatal(tag: string, format: string, ...args: any[]): void {
    hilog.fatal(AGC_DOMAIN, Logger.prefixTag(tag), format, args);
  }

  static isLoggable(tag: string, level: LogLevel): boolean {
    return hilog.isLoggable(AGC_DOMAIN, Logger.prefixTag(tag), level);
  }

  private static prefixTag(tag: string): string {
    return 'AGC_' + tag;
  }
}
