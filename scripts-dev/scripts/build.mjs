#!/usr/bin/env node
// 把 src/ 下每个 .ts 打包成 dist/<name>.js（单文件、自包含第三方库）。
// 产物末尾保留对入口函数的引用，满足 App「最后一个表达式必须是函数」的约定。
import { context, build } from "esbuild";
import { readdirSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const watch = process.argv.includes("--watch");

const entries = readdirSync(join(root, "src"))
  .filter((f) => f.endsWith(".ts"))
  .map((f) => join(root, "src", f));

if (entries.length === 0) {
  console.error("src/ 下没有 .ts 文件");
  process.exit(1);
}

mkdirSync(join(root, "dist"), { recursive: true });

const options = {
  entryPoints: entries,
  outdir: join(root, "dist"),
  bundle: true,
  format: "iife",
  globalName: "__noletEntry",
  platform: "browser", // 引用 node 内置模块（fs 等）直接构建报错
  target: "es2020",
  minify: true, // 去空白/注释、缩短标识符、压缩语法
  legalComments: "none", // 内联依赖的许可证注释一并删除
  // iife 把导出挂到 __noletEntry 上；末尾引用 default 导出，
  // 使脚本求值的完成值就是入口函数。
  footer: { js: "__noletEntry.default;" },
  logLevel: "info",
};

if (watch) {
  const ctx = await context(options);
  await ctx.watch();
  console.log("watch 中，修改 src/ 自动打包到 dist/…（Ctrl-C 退出）");
} else {
  await build(options);
}
