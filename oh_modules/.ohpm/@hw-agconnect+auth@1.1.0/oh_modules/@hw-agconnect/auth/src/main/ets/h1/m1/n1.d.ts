export declare const AGC_DOMAIN = 34959;
export declare enum LogLevel {
    DEBUG = 3,
    INFO = 4,
    WARN = 5,
    ERROR = 6,
    FATAL = 7
}
export declare class Logger {
    static debug(tag: string, format: string, ...args: any[]): void;
    static info(tag: string, format: string, ...args: any[]): void;
    static warn(tag: string, format: string, ...args: any[]): void;
    static error(tag: string, format: string, ...args: any[]): void;
    static fatal(tag: string, format: string, ...args: any[]): void;
    static isLoggable(tag: string, level: LogLevel): boolean;
    private static prefixTag;
}
