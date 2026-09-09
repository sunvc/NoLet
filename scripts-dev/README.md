# NoLet 脚本 TS 开发脚手架

用 TypeScript 开发 App 内的沙盒脚本（语音 / 处理器 / 动作 / 插件），编辑时自动补全运行时 API、参数类型，并编译成可直接粘贴进 App 的 JS。

类型声明对照 App 源码维护：`JSRuntime.swift`（通用运行时）与 `PluginProcessor.swift`（插件方法）。

## 使用

```bash
cd scripts-dev
npm install     # 会自动链接 npx 短命令
npx watch       # 监听打包
```

命令（都是 `npx <命令> [参数]`，参数不用加 `--`）：

| 命令 | 作用 |
|---|---|
| `npx build` | 打包 src/ 到 dist/ |
| `npx watch` | 监听并自动打包 |
| `npx new <模式> <名字>` | 从模板创建脚本 |
| `npx try [模式] [文件]` | 本地试跑脚本 |
| `npx tsc --noEmit` | 只做类型检查 |

**一次只开发一个脚本，`src/` 里只放你当前在写的那个：**

- 直接改 `src/script.ts` 这个起步文件即可；打包产物是 `dist/script.js`。
- 想用某模式的完整模板，用脚手架创建（会从 `templates/` 复制）：

```bash
npx new tts my-voice        # 语音
npx new processor forward   # 处理器
npx new action buttons      # 动作
npx new plugin my-plugin    # 插件
```

- 打开 `dist/` 里同名的 `.js`，全选复制，粘贴到 App「脚本」页的编辑器保存。
- 换下一个脚本时把 `src/` 里旧的 `.ts` 删掉即可。
- App 编辑器里的「测试/校验」会用示例参数真实运行一次。

## 本地测试

不用进 App，`npx try` 会用 App 同款示例参数在 Node 里真实调用入口函数：

```bash
npx try tts                 # 语音，参数 { call: "Hello World!" }
npx try processor           # 处理器（默认）
npx try action              # 动作，参数带 actionmode: "custom"
npx try plugin              # 插件，传通知快照 note
npx try plugin src/my.ts    # 指定文件（默认取 src/ 下第一个 .ts）
```

环境模拟方式：

- `fetch`、定时器、`TextEncoder`、`URL`、`crypto.randomUUID` 等用 Node 原生实现，**网络请求会真的发出**，可以打你的真实接口。
- `storage` 是内存模拟，进程退出即清空，结束时打印内容。
- 插件方法（`setContent`/`attach`/`setAvatar`/`setSound`/`archive`）只打印调用记录；`decrypt` 依赖 App 密钥，本地不可测。
- 试跑用未压缩打包，报错堆栈可读；`dist/` 产物仍是压缩版。

最终行为以 App 内「测试/校验」为准（运行时长、音频转码、附件下载等只能在 App 里验证）。

## 第三方库

直接 `npm install <库>` 然后 `import`，打包时会把依赖编译进同一个 JS 文件，复制进 App 的就是自包含单文件：```ts
import dayjs from "dayjs";

export default async function (p: ProcessorParams) {
  await fetch("https://example.com/hook", {
    method: "POST",
    body: JSON.stringify({ time: dayjs().format(), body: p.body }),
  });
}
```

注意库必须是**纯 JS / 浏览器兼容**的：引用 Node 内置模块（`fs`、`Buffer`、`process` 等）的库在构建时就会报错；操作 `document`/`window` 的库能打包但沙盒里运行会失败。另外服务扩展有几十秒运行时长限制，注意打包体积和库的初始化耗时。

## 入口约定

脚本必须 `export default` 一个函数，App 执行时调用它（打包后末尾会自动引用该函数，满足运行时「最后一个表达式必须是函数」的要求）：

```ts
export default async function handler(p: ProcessorParams): Promise<void> {
  await fetch("https://example.com/hook", { method: "POST", body: JSON.stringify(p) });
}
```

## 四种模式的入口参数

| 模式 | 参数类型 | 返回值 |
|---|---|---|
| 语音 tts | `TTSParams`（待朗读文本在 `call`） | `Promise<Uint8Array>` 音频字节 |
| 处理器 processor | `ProcessorParams`（通知字段） | 忽略 |
| 动作 action | `ActionParams`（通知字段 + `actionmode`） | 正常结束即成功，抛错显示错误 |
| 插件 plugin | `PluginNote`（通知快照 `note`） | `void` 接管 / `PluginResult` 放行 |

插件专属方法（`setContent` / `attach` / `setAvatar` / `setSound` / `archive` / `decrypt`）已在类型中标注「仅插件模式」，其他模式调用运行时会报未定义。

## 运行时 API（所有模式可用）

`fetch`（返回自定义 `Response`，仅 http/https）、`Headers`、`AbortController`、
`crypto.getRandomValues` / `randomUUID` / `_hmacSha256Base64`、
`storage.get/set/remove`（按脚本隔离、跨启动持久）、
`setTimeout/setInterval`、`btoa/atob`、`TextEncoder/TextDecoder`、
`URL/URLSearchParams`、`structuredClone`、`console.*`、`performance.now()`。

语言标准为 ES2020；没有 `document`、`window`、`Buffer`、`process`，
类型里不存在的 API 用了会直接报编译错误。

## 目录

```
scripts-dev/
├── types/nolet-runtime.d.ts   # 运行时全部 API 与参数类型（改 API 时更新这里）
├── templates/                 # 四种模式的完整示例模板（npx new 的来源，不参与编译）
├── src/                       # 当前在开发的脚本（一次一个）
└── dist/                      # esbuild 打包产物（依赖已内联，自包含单文件），复制进 App
```
