#!/usr/bin/env node
// 从 templates/ 复制一个模式模板到 src/<name>.ts
import { copyFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const [mode, name] = process.argv.slice(2);
const modes = ["tts", "processor", "action", "plugin"];

if (!modes.includes(mode) || !name) {
  console.log("用法: npx new <tts|processor|action|plugin> <脚本名>");
  console.log("例:  npx new tts my-voice");
  process.exit(1);
}

mkdirSync(join(root, "src"), { recursive: true });
const dest = join(root, "src", `${name}.ts`);
if (existsSync(dest)) {
  console.error(`已存在: src/${name}.ts，换个名字或先删掉它`);
  process.exit(1);
}

copyFileSync(join(root, "templates", `${mode}.ts`), dest);
console.log(`已创建 src/${name}.ts（模板: ${mode}）`);
console.log(`npx watch 后，把 dist/${name}.js 的内容复制进 App 脚本编辑器`);
