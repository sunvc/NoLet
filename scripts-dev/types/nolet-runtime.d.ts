/*!
 * NoLet 沙盒脚本运行时类型声明
 * 对应 Publics/Managers/JSRuntime.swift（polyfill）与 ServiceExtension/Handler/PluginProcessor.swift
 *
 * 本文件为全局 ambient 声明，脚本里无需 import，直接获得补全。
 * 运行时只有 ES2020 语言标准 + 下列 API，没有 document/window/Buffer/process。
 */

// ================================ 脚本入口参数 ================================

/** 通知字段对象（tts / processor / action 三种模式的入口参数） */
interface NotifyParams {
  title?: string;
  subtitle?: string;
  body?: string;
  group?: string;
  category?: string;
  /** 推送携带的其他自定义字段 */
  [key: string]: any;
}

/** 语音脚本入口参数：待朗读文本在 call 字段（非 URL 文本时才走脚本） */
interface TTSParams extends NotifyParams {
  call?: string;
}

/** 处理器脚本入口参数：通知完整字段对象 */
interface ProcessorParams extends NotifyParams {}

/** 动作脚本入口参数：通知字段 + 被点击按钮的标识 */
interface ActionParams extends NotifyParams {
  /** 被点击按钮的标识，同一脚本绑多个按钮时用它区分 */
  actionmode: string;
  /** 推送 reply 字段时为回复接口 URL */
  reply?: string;
}

/** 中断级别 */
type NotifyLevel = "passive" | "active" | "timesensitive" | "critical";

/** 插件脚本入口参数：进入插件时的通知只读快照（setContent 不会改变它） */
interface PluginNote {
  /** 通知标识（targetContentIdentifier） */
  id: string;
  title: string;
  subtitle: string;
  body: string;
  /** 分组（threadIdentifier） */
  group: string;
  category: string;
  badge: number | null;
  level: NotifyLevel;
  /** 推送的完整自定义字段对象 */
  userInfo: Record<string, any>;
}

/** 插件脚本返回值：不返回/undefined = 接管；continue:true = 放行并保留修改；continue:"original" = 放行并丢弃修改 */
interface PluginResult {
  continue: boolean | "original";
}

// ================================ fetch / HTTP ================================

type HeadersInit = Headers | Record<string, string> | Array<[string, string]>;

declare class Headers {
  constructor(init?: HeadersInit);
  append(name: string, value: string): void;
  set(name: string, value: string): void;
  get(name: string): string | null;
  has(name: string): boolean;
  forEach(callback: (value: string, name: string) => void): void;
}

interface FetchInit {
  method?: string;
  headers?: HeadersInit;
  /** string 按 UTF-8 编码；Uint8Array/ArrayBuffer 直接发送字节 */
  body?: string | ArrayBuffer | ArrayBufferView;
  signal?: AbortSignal;
}

declare class Response {
  readonly status: number;
  readonly ok: boolean;
  readonly statusText: string;
  readonly headers: Headers;
  readonly url: string;
  text(): Promise<string>;
  json<T = any>(): Promise<T>;
  arrayBuffer(): Promise<ArrayBuffer>;
}

/**
 * HTTP(S) 请求。仅允许 http/https 协议；
 * host、content-length、connection 等请求头被原生侧禁用。
 */
declare function fetch(input: string | { url: string }, init?: FetchInit): Promise<Response>;

interface AbortSignal {
  readonly aborted: boolean;
  addEventListener(type: "abort", listener: (event: { type: string }) => void): void;
  removeEventListener(type: "abort", listener: (event: { type: string }) => void): void;
}

declare class AbortController {
  readonly signal: AbortSignal;
  abort(): void;
}

declare class DOMException extends Error {
  constructor(message?: string, name?: string);
}

// ================================ crypto ================================

interface Crypto {
  /** 用随机字节填充 typed array 并返回同一对象 */
  getRandomValues<T extends ArrayBufferView>(array: T): T;
  randomUUID(): string;
  /** HMAC-SHA256 签名；key 与返回值均为 base64 */
  _hmacSha256Base64(keyB64: string, message: string): string;
}

declare var crypto: Crypto;

// ================================ storage（按脚本文件隔离，跨启动持久） ================================

interface ScriptStorage {
  /** 不存在返回 null；支持 string/number/boolean/对象/Uint8Array */
  get<T = any>(key: string): T | null;
  set(key: string, value: string | number | boolean | object | ArrayBuffer | ArrayBufferView | null): void;
  remove(key: string): void;
}

declare var storage: ScriptStorage;

// ================================ 定时器 ================================

declare function setTimeout(handler: () => void, ms?: number): number;
declare function setInterval(handler: () => void, ms?: number): number;
declare function clearTimeout(id: number): void;
declare function clearInterval(id: number): void;
declare function queueMicrotask(callback: () => void): void;

declare var performance: {
  now(): number;
};

// ================================ Base64 / UTF-8 ================================

/** binary string → base64 */
declare function btoa(input: string): string;
/** base64 → binary string */
declare function atob(input: string): string;

declare class TextEncoder {
  readonly encoding: "utf-8";
  constructor();
  encode(input?: string): Uint8Array;
}

/** 仅支持 utf-8，其他 label 抛 RangeError */
declare class TextDecoder {
  readonly encoding: string;
  constructor(label?: string);
  decode(input?: ArrayBufferView | ArrayBuffer): string;
}

// ================================ URL ================================

declare class URLSearchParams {
  constructor(init?: string | Record<string, string> | Array<[string, string]>);
  append(name: string, value: string): void;
  get(name: string): string | null;
  has(name: string): boolean;
  set(name: string, value: string): void;
  delete(name: string): void;
  forEach(callback: (value: string, name: string) => void): void;
  toString(): string;
}

declare class URL {
  constructor(url: string, base?: string);
  protocol: string;
  host: string;
  hostname: string;
  port: string;
  pathname: string;
  search: string;
  hash: string;
  origin: string;
  searchParams: URLSearchParams;
  toString(): string;
}

// ================================ 其他全局 ================================

/** 基于 JSON 的深拷贝（函数/循环引用不支持） */
declare function structuredClone<T>(value: T): T;

declare var console: {
  log(...args: any[]): void;
  info(...args: any[]): void;
  debug(...args: any[]): void;
  warn(...args: any[]): void;
  error(...args: any[]): void;
};

// ================================ 插件专属方法（仅 plugin 模式可用） ================================
// 其他三种模式调用会报"未定义"。

/** 通知内容补丁，缺省字段不变 */
interface ContentPatch {
  title?: string;
  subtitle?: string;
  body?: string;
  group?: string;
  category?: string;
  id?: string;
  level?: NotifyLevel;
  /** <= 0 清零，同时同步共享未读计数 */
  badge?: number;
}

/** 附件选项：图片下载，或地图快照（location 为 "纬度,经度"，支持中文逗号/冒号分隔） */
type AttachOptions =
  | { type: "image"; url: string }
  | { type: "map"; location: string };

/** archive 落库消息；缺省字段自动补全（id/createDate/read/group） */
interface ArchiveMessage {
  id?: string;
  title?: string;
  subtitle?: string;
  body?: string;
  group?: string;
  url?: string;
  /** 过期秒数；-1 永不过期 */
  ttl?: number;
  style?: string;
  other?: Record<string, any> | string;
}

/** 修改通知内容（仅插件模式） */
declare function setContent(patch: ContentPatch): Promise<void>;

/** 下载图片附件或生成地图快照，成功返回 true（仅插件模式） */
declare function attach(options: AttachOptions): Promise<boolean>;

/** 设置发送者头像：图片 URL 或 App 内已配置的图标名（仅插件模式） */
declare function setAvatar(urlOrIconName: string): Promise<boolean>;

/**
 * 设置铃声（仅插件模式）：
 * 内置铃声名 "typewriter"（自动补 .caf）/ { url } 下载远程音频 / { tts } 调用语音脚本合成
 */
declare function setSound(spec: string | { url?: string; tts?: string }): Promise<boolean>;

/**
 * 写入跨进程收件箱供主 App 入库（仅插件模式）。
 * 返回 true = 新消息（未读数 +1），false = 同 id 已存在（去重）。
 */
declare function archive(message: ArchiveMessage): Promise<boolean>;

/**
 * 用 App 内配置的密钥解密（仅插件模式）。
 * cipherNumber 为密钥列表序号，默认 0；返回明文字段对象（键名小写）。
 */
declare function decrypt(ciphertext: string, cipherNumber?: number): Promise<Record<string, any>>;
