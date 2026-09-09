// 直接改这个文件开发你的脚本。
// 想用某模式的完整模板，运行：npx new <tts|processor|action|plugin> <名字>
// 打包后把 dist/script.js 内容复制进 App 脚本编辑器。
// 入口约定：export default 一个函数（App 执行时调用它）。
// 第三方库直接 import，npm 安装后会被打包进同一个文件。
import dayjs from "dayjs";
import { gcm } from "@noble/ciphers/aes.js";

export default async function handler(p: NotifyParams): Promise<void> {
  console.log("收到推送:", p.title, p.body);
  console.log("收到推送时间:", dayjs().format("YYYY-MM-DD HH:mm:ss"));
  const key = crypto.getRandomValues(new Uint8Array(32));  // 或固定/协商的密钥
  const iv = crypto.getRandomValues(new Uint8Array(12));   // GCM 要求同一密钥下 nonce 绝不复用
  const ct = gcm(key, iv).encrypt(new TextEncoder().encode(JSON.stringify(p)));
  console.log("加密后的推送内容:", ct);
}

