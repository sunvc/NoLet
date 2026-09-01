# 脚本扩展

伞兵(BravoPapa) 支持用 JavaScript 脚本扩展通知行为。脚本在 App 内置的沙盒 JavaScript 运行时中执行，可使用 `fetch`、`crypto`、`storage`、`setTimeout`、`console` 等标准 API，按用途分为四种模式。

在 App「脚本」页面新建脚本时选择模式：

| 模式 | 触发时机 | 运行位置 | 入口参数 | 返回值 |
|------|----------|----------|----------|--------|
| **语音 (tts)** | 推送 `call` 为待朗读文本时 | 通知服务扩展（后台） | 通知字段对象 | 音频字节（Uint8Array） |
| **处理器 (processor)** | 推送携带 `script` 字段时 | 通知服务扩展（后台） | 通知字段对象 | 忽略（做副作用） |
| **动作 (action)** | 用户点击绑定脚本的通知按钮时 | 通知内容扩展（交互界面） | 通知字段 + `actionmode` | 成功/失败提示 |
| **插件 (plugin)** | 推送携带 `plugin` 字段时 | 通知服务扩展（后台，处理链最前） | 通知快照 `note` | 接管/放行 |

> 插件模式能力最强（可改通知内容、附件、声音、落库、解密等），单独有一份完整文档：[通知插件](/plugin)。本文介绍所有模式共用的基础，以及语音/处理器/动作三种模式。

---

## 脚本基础

#### 入口约定

脚本的**最后一个表达式必须是一个函数**，App 执行时调用它。异步逻辑用 `async function`：

```js
async function (params) {
  // params 为传入的参数对象
  const res = await fetch("https://example.com/api", {
    method: "POST",
    body: JSON.stringify(params)
  });
  return await res.text();
}
```

在脚本编辑页点「测试/校验」时，App 会用各模式的示例参数真正运行一次脚本（语音传 `{call:"Hello World!"}`、处理器传 `{title,subtitle,body}`、动作传 `{actionmode:"custom"}`）。

#### 运行时 API（所有模式可用）

| API | 说明 |
|---|---|
| `fetch(url, init)` | HTTP(S) 请求，返回 `Response`（`text()`/`json()`/`arrayBuffer()`）；仅 http/https |
| `crypto.getRandomValues` / `crypto.randomUUID()` | 随机数 / UUID |
| `crypto._hmacSha256Base64(keyB64, msg)` | HMAC-SHA256 签名（key、返回值均 base64） |
| `storage.get/set/remove(key)` | 按脚本隔离的持久化键值存储，跨启动保留（字符串/数字/布尔/对象/字节） |
| `setTimeout` / `setInterval` / `clearTimeout` | 定时器 |
| `btoa` / `atob` / `TextEncoder` / `TextDecoder` | Base64 与 UTF-8 编解码 |
| `URL` / `URLSearchParams` | URL 解析与构造 |
| `structuredClone(v)` | 深拷贝（基于 JSON） |
| `console.log/info/warn/error` | 输出日志，可在 App 日志中查看 |

> 插件专属方法（`setContent`/`attach`/`setAvatar`/`setSound`/`archive`/`decrypt`）**仅插件模式**可用，其余三种模式调用会报"未定义"。

#### 存储隔离

`storage` 按脚本文件隔离，不同脚本互不可见；同一脚本跨通知、跨启动保留。适合缓存 token、计数、去重状态等。

---

## 语音脚本（tts）

当推送的 `call` 字段是一段**文本**（不是 http 链接）时，App 调用语音脚本合成音频，作为通知铃声播放（最长约 30 秒）。

- 触发：`call` 为非 URL 文本。（`call` 为 http 链接时直接下载音频；`call: true` 时播放长铃声，都不走脚本。）
- 入口参数：通知完整字段对象，待朗读文本在 `call` 字段。
- **返回值**：音频文件的字节（`Uint8Array` / `ArrayBuffer`，如 MP3）。App 会写入并转成 CAF 播放。

**示例：调用在线 TTS 接口合成语音**

```js
async function (p) {
  const text = p.call || "你有新消息";
  const res = await fetch("https://your-tts.example.com/synthesize", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ text: text, voice: "zh-CN" })
  });
  if (!res.ok) throw new Error("tts failed: " + res.status);
  // 返回音频二进制（MP3 等可被系统识别的格式）
  return new Uint8Array(await res.arrayBuffer());
}
```

推送示例：

```json
{ "title": "来电提醒", "body": "点击查看", "call": "张三：下班一起吃饭吗" }
```

---

## 处理器脚本（processor）

当推送携带 `script` 字段（值为脚本名）时，App 在后台执行处理器脚本。它**不改变通知显示**，用于做副作用：转发到 Webhook、写日志、联动自家服务、统计计数等。

- 触发：`script` 字段 = 处理器脚本名（不含 `.js`）。
- 入口参数：通知完整字段对象（`title`/`subtitle`/`body`/`group` 及自定义字段）。
- 返回值：忽略。

**示例：把通知转发到自己的服务**

```js
async function (p) {
  await fetch("https://your-server.example.com/hook", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      title: p.title, body: p.body, group: p.group,
      receivedAt: Date.now()
    })
  });
}
```

推送示例：

```json
{ "title": "服务器告警", "body": "CPU 使用率 92%", "script": "forward-alert" }
```

---

## 动作脚本（action）

当用户在通知上点击一个**绑定了脚本的自定义按钮**时执行（见下方[自定义操作按钮](#自定义操作按钮)）。脚本运行在通知下拉界面里，适合"点一下按钮就调接口"的场景：确认收到、一键打卡、触发设备控制等。

- 触发：用户点击绑定了该脚本的自定义按钮。
- 入口参数：通知完整字段对象，额外带一个 `actionmode` 字段——被点击按钮的标识。同一个脚本绑到多个按钮时，可用它区分用户点了哪个。
- 返回值：正常完成显示"执行成功"；抛错（或 Promise reject）则显示错误信息。

**示例：根据按钮执行不同操作**

```js
async function (p) {
  const action = p.actionmode;          // 被点击按钮的标识
  const base = p.reply || "https://your-server.example.com/action";
  const res = await fetch(base + "?mode=" + encodeURIComponent(action), {
    method: "POST"
  });
  if (!res.ok) throw new Error("HTTP " + res.status);
  // 正常返回即提示"执行成功"
}
```

---

## 通知分类（Identifiers）

通知上显示哪些按钮，由它的**分类标识（category）**决定。App 内置三类系统分类，外加 26 个可自定义分类。

#### 系统分类（自动选择，无需配置）

| 分类标识 | 用途 | 自带按钮 |
|---|---|---|
| `myNotificationCategory` | 普通通知（默认） | 复制、静音分组1小时、翻译、总结 |
| `markdown` | Markdown 富文本通知（`style: "markdown"`） | 复制、静音分组1小时、翻译、总结 |
| `reply` | 带回复框的通知（推送含 `reply` 字段 URL） | 文本输入回复 |

普通通知不指定分类时，App 会根据 `style` / `reply` 自动选用以上分类。

#### 自定义分类（alfa – zulu）

App 提供 26 个自定义分类标识，取自北约音标字母：

```
alfa  bravo  charlie  delta  echo  foxtrot  golf  hotel  india
juliett  kilo  lima  mike  november  oscar  papa  quebec
romeo  sierra  tango  uniform  victor  whiskey  xray  yankee  zulu
```

在 App「通知设置 → 分类」里，为其中某个分类配置按钮，然后推送时把**分类标识**设为该值，通知就会显示你配置的按钮。

推送示例（让通知使用 `alfa` 分类的按钮）：

```json
{ "title": "门禁", "body": "有人按门铃", "category": "alfa" }
```

> `category` 对应 APNs 的通知分类。系统分类（markdown/reply）通常由 App 按内容自动设置；要用自定义按钮就显式传 alfa–zulu 之一。

---

## 自定义操作按钮

在 App「通知设置」里为一个自定义分类（alfa–zulu）添加按钮。按钮分两种：

#### 内置操作按钮

直接选用内置动作，无需写脚本：

| 内置动作 | 行为 |
|---|---|
| 复制 | 复制通知的 `copy` 字段内容，没有则复制正文 |
| 静音分组1小时 | 把该通知所在分组静音 1 小时 |
| 翻译 | 用 AI 翻译通知正文 |
| 总结 | 用 AI 总结通知正文 |

#### 自定义按钮（可绑定动作脚本）

设置按钮标题和图标，点击行为：

- **绑定了动作脚本**：点击时在通知界面执行该脚本（即上面的[动作脚本](#动作脚本action)），脚本可通过参数里的 `actionmode` 知道是哪个按钮被点了。
- **未绑定脚本**：点击仅打开 App。

#### 配置步骤

1. 打开 App「通知设置 → 分类」，选择一个自定义分类（如 `alfa`）。
2. 添加按钮：选内置动作，或新建自定义按钮（填写标题、图标）。
3. 自定义按钮可选择绑定一个**动作模式**的脚本。
4. 推送时设置 `category` 为该分类标识（如 `alfa`），通知即出现这些按钮。

#### 一个分类配多个按钮、共用一个脚本

把同一个动作脚本绑到同一分类的多个按钮上，脚本用 `actionmode` 区分：

```js
async function (p) {
  switch (p.actionmode) {
    case "approve": await fetch("https://example.com/approve", { method: "POST" }); break;
    case "reject":  await fetch("https://example.com/reject",  { method: "POST" }); break;
  }
}
```

---

## 限制与注意

- 通知服务扩展（语音/处理器/插件）有运行时长上限（系统约几十秒），网络请求应尽快完成；超时系统按原始通知投递。
- 动作脚本运行在通知内容扩展，依赖用户点开通知交互；执行期间界面会显示"执行脚本中"。
- `fetch` 仅允许 `http`/`https`，且 `host`、`content-length` 等请求头被禁用。
- 语音脚本需返回系统可识别的音频格式字节（如 MP3），时长上限约 30 秒。
- 插件模式每次通知新建运行时（改脚本立即生效）；语音脚本运行时会复用，修改后可能需重启才生效。
- 脚本错误会记录到 App 日志，可用 `console.log` 辅助调试。
