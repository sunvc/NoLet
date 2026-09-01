# 通知插件

通知插件是一种用 JavaScript 脚本**完全接管**一条通知在通知服务扩展（Notification Service Extension）里处理过程的机制。

普通推送由 App 内置的固定流程处理（解密 → 落库 → 角标 → 声音 → 附件/头像）。当推送携带 `plugin` 参数时，App 会在流程最开始执行你编写的插件脚本，由脚本决定这条通知怎么显示、是否入库、用什么声音、加什么附件——脚本可以调用与内置流程等价的原生能力，然后终止内置流程。

> 插件在沙盒 JavaScript 运行时中执行，可使用 `fetch`、`crypto`、`storage`、`setTimeout`、`console` 等标准 API，以及下面列出的插件专属原生方法。

#### 适用场景

- 自定义解密 / 字段改写逻辑，不想受内置加密格式限制
- 按消息内容决定通知标题、分组、中断级别、角标
- 条件性地下载图片附件、生成地图快照、设置发送者头像
- 自定义铃声（下载音频或调用 TTS 语音脚本合成）
- 自主决定消息是否落库、未读数如何变化

#### 安装与触发

1. 在 App「脚本」页面新建一个脚本，**类型选择「插件」**，编辑并保存。
2. 推送时携带 `plugin` 参数，值为脚本名（不含 `.js`）：

```json
{
  "plugin": "my-plugin",
  "title": "会被插件改写的标题",
  "body": "任意自定义字段",
  "mydata": "..."
}
```

收到推送后，App 查找名为 `my-plugin`、类型为「插件」的脚本并执行。找不到脚本或脚本抛错时，回退到内置流程处理。

#### 脚本入口

脚本最后一个表达式必须是一个 `async function`，它接收一个参数 `note`——当前通知的只读快照：

```js
async function (note) {
  // note 字段：
  // note.id        通知标识（targetContentIdentifier）
  // note.title     标题
  // note.subtitle  副标题
  // note.body      正文
  // note.group     分组（threadIdentifier）
  // note.category  分类标识
  // note.badge     角标数字
  // note.level     中断级别：passive / active / timesensitive / critical
  // note.userInfo  推送的完整自定义字段对象
}
```

> `note` 是**进入插件时的原始通知快照**，脚本里调用 `setContent` 等方法不会改变它。要基于修改后的内容做判断，请用自己的变量记录。

#### 接管 / 放行

脚本通过返回值决定后续行为：

- **不返回 / 返回 `undefined`**：插件已接管，**内置流程不再执行**。落库、角标、声音、附件等都由脚本自己调用对应方法完成。
- **返回 `{ continue: true }`**：放行，内置流程在**插件修改后**的通知内容上继续执行（脚本已做的修改保留）。
- **返回 `{ continue: "original" }`**：放行，但**丢弃插件的所有修改**，内置流程在**原始通知**上执行。适合脚本只做副作用（如上报、打点）而不想影响通知本身。
- **脚本抛错**：记录错误日志，回退到内置流程（此时保留脚本出错前已做的修改）。

```js
async function (note) {
  // 只上报、不改通知：用原始内容继续走内置流程
  await fetch("https://example.com/track", {
    method: "POST",
    body: JSON.stringify(note.userInfo)
  });
  return { continue: "original" };
}
```

```js
async function (note) {
  // 改写标题后，让内置流程在修改后的内容上继续（解密/落库/声音等照常）
  await setContent({ title: "改写后的标题" });
  return { continue: true };
}
```

> 注意：`continue: "original"` 只会回滚**通知内容**（标题、正文、附件、头像、声音等）。脚本已经产生的**副作用不会撤销**——例如 `archive()` 已落库的消息、`storage` 写入、`fetch` 发出的网络请求依然有效。若要"纯副作用且不留痕迹"，不要在 `original` 之前调用会改内容的方法即可（副作用本身按需要保留）。

---

## 原生方法

所有插件方法都是全局异步函数，返回 Promise，用 `await` 调用。

### setContent(patch)

修改通知内容。`patch` 对象里只需提供要改的字段，缺省字段不变。

| 字段 | 类型 | 说明 |
|---|---|---|
| `title` | string | 标题 |
| `subtitle` | string | 副标题 |
| `body` | string | 正文 |
| `group` | string | 分组（线程标识） |
| `category` | string | 通知分类标识 |
| `id` | string | 通知标识（用于去重/落库） |
| `level` | string | 中断级别：`passive` / `active` / `timesensitive` / `critical` |
| `badge` | number | 角标数字；`<= 0` 清零，同时同步共享未读计数 |

```js
await setContent({ title: "新标题", body: "新正文", level: "timesensitive", badge: 5 });
```

### attach(options)

下载图片或生成地图快照，作为通知附件。成功返回 `true`。

- 图片附件：`{ type: "image", url: "https://..." }`
- 地图快照：`{ type: "map", location: "纬度,经度" }`（也支持中文逗号/冒号分隔）

```js
if (note.userInfo.image) {
  await attach({ type: "image", url: note.userInfo.image });
}
await attach({ type: "map", location: "39.90,116.40" });
```

### setAvatar(urlOrIconName)

设置通知的发送者头像（通过 Intents 捐赠实现）。参数可以是图片 URL，也可以是 App 内已配置的图标名。成功返回 `true`。

```js
await setAvatar(note.userInfo.icon || "https://example.com/a.png");
```

### setSound(spec)

设置通知铃声，成功返回 `true`。三种形式：

- 内置铃声名：`setSound("typewriter")`（自动补 `.caf` 后缀）
- 下载远程音频并转换：`setSound({ url: "https://example.com/a.mp3" })`
- 调用 TTS 语音脚本合成：`setSound({ tts: "要朗读的文本" })`

```js
await setSound("alarm");
await setSound({ tts: note.body });
```

> 中断级别为 `critical` 时会按临界警告声音处理（受音量参数影响）。

### archive(message)

把消息写入跨进程收件箱，供主 App 入库展示。返回 `true` 表示是一条**新消息**（会自动把共享未读数 +1），`false` 表示同 id 消息已存在（去重）。

`message` 对象常用字段：`id`、`title`、`subtitle`、`body`、`group`、`url`、`ttl`、`style`、`other`。
缺省字段会自动补全：`id`（取通知 id 或随机生成）、`createDate`（当前时间）、`read`（false）、`group`（取当前通知分组）。

```js
const isNew = await archive({
  title: note.title,
  body: note.body,
  group: note.group,
  ttl: 3600,           // 过期秒数；-1 表示永不过期
  other: { custom: "x" }
});
```

> 接管模式下内置流程**不会自动落库**，需要消息出现在 App 列表里就必须显式调用 `archive()`。

### decrypt(ciphertext, cipherNumber?)

用 App 内配置的加密密钥解密密文，返回明文字段对象（键名为小写）。`cipherNumber` 为密钥列表序号，默认 `0`。

```js
const info = note.userInfo;
if (info.ciphertext) {
  const m = await decrypt(info.ciphertext, info.ciphernumber || 0);
  await setContent({ title: m.title, body: m.body, group: m.group });
}
```

---

## 运行时内置 API

插件运行时还提供以下标准能力（与 TTS / 动作脚本一致）：

| API | 说明 |
|---|---|
| `fetch(url, init)` | 发起 HTTP(S) 请求，返回 `Response`；支持 `method`/`headers`/`body`/`signal`（AbortController） |
| `crypto.getRandomValues` / `crypto.randomUUID()` | 随机数 / UUID |
| `crypto._hmacSha256Base64(keyB64, msg)` | HMAC-SHA256 签名（key、返回值均为 base64） |
| `storage.get/set/remove(key)` | 按脚本隔离的持久化键值存储，跨启动保留（支持字符串/数字/布尔/对象/字节） |
| `setTimeout` / `setInterval` / `clearTimeout` | 定时器 |
| `btoa` / `atob` / `TextEncoder` / `TextDecoder` | Base64 与 UTF-8 编解码 |
| `URL` / `URLSearchParams` | URL 解析与构造 |
| `structuredClone` | 深拷贝（基于 JSON） |
| `console.log/info/warn/error` | 输出日志（可在 App 日志中查看） |

---

## 完整示例

**自定义解密 + 附件 + 头像 + 落库的接管插件：**

```js
async function (note) {
  const info = note.userInfo;

  // 1. 自定义解密
  let m = { title: note.title, body: note.body, group: note.group };
  if (info.ciphertext) {
    try { m = await decrypt(info.ciphertext, info.ciphernumber || 0); }
    catch (e) { console.error("decrypt failed", e); }
  }

  // 2. 改写通知内容
  await setContent({
    title: m.title,
    body: m.body,
    group: m.group || "默认",
    level: info.pinned ? "timesensitive" : "active",
    badge: info.badge
  });

  // 3. 附件与头像
  if (info.image) await attach({ type: "image", url: info.image });
  if (info.location) await attach({ type: "map", location: info.location });
  if (info.icon) await setAvatar(info.icon);

  // 4. 声音
  if (info.call) {
    await setSound({ tts: m.body });         // 来电式语音播报
  } else if (info.sound) {
    await setSound(info.sound);
  }

  // 5. 落库（否则消息不会进入 App 列表）
  await archive({
    title: m.title, subtitle: m.subtitle, body: m.body,
    group: m.group, url: info.url, ttl: info.ttl,
    other: info
  });
}
```

**调用远程接口决定通知内容：**

```js
async function (note) {
  const res = await fetch("https://example.com/api/notify", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(note.userInfo)
  });
  if (!res.ok) return { continue: true };     // 接口失败则放行内置流程
  const rule = await res.json();
  if (rule.mute) {
    await setContent({ level: "passive" });
  }
  if (rule.title) await setContent({ title: rule.title });
}
```

---

## 限制与注意

- 通知服务扩展有运行时长上限（系统约几十秒），超时系统会按原始内容投递。插件应尽快完成，网络请求建议控制在数秒内。
- 脚本执行有超时保护；长时间同步死循环无法被中断，请避免编写无限同步循环。
- `fetch` 仅允许 `http`/`https`；请求头中 `host`、`content-length` 等被禁用。
- 插件每次通知都会新建运行时，修改脚本后下一条通知立即生效。
- `storage` 按脚本文件隔离，不同插件互不干扰。
