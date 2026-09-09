#!/usr/bin/env node
// 本地试跑：用模拟的 App 运行时调用 src/ 脚本的入口函数。
// 用法: npx try [tts|processor|action|plugin] [src/xxx.ts]
// 不传文件时取 src/ 下第一个 .ts。fetch 走真实网络，storage 为内存模拟。
import { build } from "esbuild";
import { readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createHmac } from "node:crypto";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const mode = process.argv[2] || "processor";
const fileArg = process.argv[3];

const sampleArgs = {
  tts: [{ call: "Hello World!" }],
  processor: [{ title: "Test", subtitle: "Test", body: "Test" }],
  action: [{ title: "Test", body: "Test", actionmode: "custom" }],
  plugin: [{
    id: "test-id",
    title: "测试标题",
    subtitle: "",
    body: "测试正文",
    group: "测试分组",
    category: "",
    badge: null,
    level: "active",
    userInfo: { plugin: "demo", custom: "x" },
  }],
};
if (!sampleArgs[mode]) {
  console.error(`未知模式 "${mode}"，可选: ${Object.keys(sampleArgs).join(", ")}`);
  process.exit(1);
}

const srcFile = fileArg
  ? join(root, fileArg)
  : join(root, "src", readdirSync(join(root, "src")).find((f) => f.endsWith(".ts")));

// ---- 模拟 App 运行时 ----
// fetch / setTimeout / TextEncoder / URL / console / crypto.getRandomValues 等
// Node 原生已有，直接用真实环境（网络请求会真的发出）。
const store = new Map();
globalThis.storage = {
  get: (k) => (store.has(k) ? store.get(k) : null),
  set: (k, v) => (v == null ? store.delete(k) : store.set(k, v)),
  remove: (k) => store.delete(k),
};
globalThis.crypto ??= {};
globalThis.crypto._hmacSha256Base64 = (keyB64, msg) =>
  createHmac("sha256", Buffer.from(keyB64, "base64")).update(msg).digest("base64");

if (mode === "plugin") {
  // 插件专属方法：打印调用记录，不做真实操作
  const record = (name) => (v) => {
    console.log(`[${name}]`, typeof v === "object" ? JSON.stringify(v) : String(v));
    return Promise.resolve(name === "setContent" ? undefined : true);
  };
  globalThis.setContent = record("setContent");
  globalThis.attach = record("attach");
  globalThis.setAvatar = record("setAvatar");
  globalThis.setSound = record("setSound");
  globalThis.archive = record("archive");
  globalThis.decrypt = () => {
    throw new Error("decrypt 依赖 App 内配置的密钥，本地无法测试，请在 App 中校验");
  };
}

// ---- 打包并取入口函数（不压缩，报错堆栈可读）----
const result = await build({
  entryPoints: [srcFile],
  bundle: true,
  write: false,
  format: "iife",
  globalName: "__entry",
  platform: "browser",
  target: "es2020",
  footer: { js: "__entry.default;" },
});
const fn = eval(result.outputFiles[0].text);
if (typeof fn !== "function") {
  console.error("入口不是函数：请 export default 一个函数");
  process.exit(1);
}

console.log(`试跑模式: ${mode}`);
console.log(`入口参数: ${JSON.stringify(sampleArgs[mode][0])}\n`);
try {
  const ret = await fn(...sampleArgs[mode]);
  if (ret instanceof Uint8Array) {
    console.log(`\n返回值: Uint8Array ${ret.byteLength} 字节（音频/二进制）`);
  } else {
    console.log("\n返回值:", ret);
  }
  if (store.size) console.log("storage 内容:", Object.fromEntries(store));
} catch (e) {
  console.error("\n脚本抛错:", e);
  process.exit(1);
}
