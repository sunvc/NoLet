# 📨 消息模板字段手册

伞电(Nolet) 的消息通过 `style` 字段来切换不同的卡片模板。本文档按模板分类，列出所有可用字段。

> **平台差异标签说明**：下文所有字段都在末尾用标签标注其生效平台，取值为
> `全平台`（Apple 与鸿蒙通用）、`apple`（仅苹果设备）、`harmony`（仅鸿蒙设备）。
>
> **重要差异**：五种卡片模板（`style`）、`other` 扩展字段、`reply`、`location` 等均为 **Apple 端能力，平台差异 `apple`**。鸿蒙端不区分模板，**所有正文统一按 Markdown 渲染**为通用卡片。

---

## Message 通用字段

所有模板都使用 `Message` 结构体作为数据源，字段分为两类：

### 用户可设置字段（通过推送 API / SDK 传入）

| 字段 | 类型 | 必填 | 说明 | 平台差异 |
|------|------|------|------|----------|
| `group` | `String` | ✅ | 群组名称 / 分类标签 | 全平台 |
| `body` | `String` | ✅ | 消息正文内容（支持 HTML 标签如 `<br/>`、`<b>`） | 全平台 |
| `title` | `String?` | - | 标题 | 全平台 |
| `subtitle` | `String?` | - | 副标题 | apple |
| `icon` | `String?` | - | 头像 / 图标 URL | 全平台 |
| `url` | `String?` | - | 外部跳转链接 | 全平台 |
| `image` | `String?` | - | 图片附件 URL | 全平台 |
| `reply` | `String?` | - | 回复接口 URL（存在即显示回复框） | apple |
| `ttl` | `Int` | - | 消息存活时长（秒），`0` 表示不归档 / 永久见各端约定 | 全平台 |
| `style` | `String?` | - | **模板选择器**，见下方各模板说明 | apple |
| `other` | `String?` | - | JSON 字符串，存放模板专属扩展字段。各模板支持的 key 见下方说明 | apple |
| `location` | `String?` | - | 经纬度 `"lat,lng"` 或回调 URL。详见下方 [📍 Location 定位功能](#-location-定位功能) | apple |

### 系统自动生成字段（无需用户设置）

| 字段 | 类型 | 说明 | 平台差异 |
|------|------|------|----------|
| `id` | `String` | 消息唯一标识，系统自动生成 UUID | 全平台 |
| `createDate` | `Date` | 消息接收/创建时间，由系统写入 | 全平台 |
| `read` | `Bool` | 已读/未读状态，由 App 管理 | 全平台 |

> `body` 在 App 内通过 `.plainText` 属性转为纯文本渲染，模板使用 `body.plainText` 展示。鸿蒙端通知正文同样在展示前去除 Markdown 标记与链接网址。

---

## 📍 Location 定位功能

> 本节整个定位功能（直接坐标与回调获取）**仅 Apple 端支持，平台差异 `apple`**。鸿蒙端不解析 `location` 字段。

`location` 字段支持两种完全不同的使用模式：**直接坐标模式**和**回调获取模式**。服务端根据 `location` 的值自动判断使用哪种模式。

### 模式判断

| `location` 值 | 模式 | 说明 | 平台差异 |
|---------------|------|------|----------|
| `"纬度,经度"` 坐标字符串 | **直接坐标模式** | 坐标直接显示在消息卡片上，并生成地图快照 | apple |
| 合法 URL（有 scheme + host） | **回调获取模式** | 触发 Apple Location Push，获取设备实际位置后 POST 到回调 URL | apple |

> 服务端通过解析 URL 来判断：能解析出 `Scheme` 和 `Host` 即为回调获取模式，否则为直接坐标模式。

---

### 模式一：直接坐标模式

传入逗号分隔的经纬度坐标，坐标会随消息一起发送到设备，在消息卡片上显示 🗺️ 地图按钮，并在通知中附加地图快照和逆地理编码地址。

#### 推送示例

```json
{
    "group": "工作",
    "title": "会议地点",
    "subtitle": "Q3 评审会",
    "body": "请准时到达会议室",
    "location": "31.2304,121.4737"
}
```

```sh
# GET 请求
curl "https://wzs.app/your_key/会议地点/Q3 评审会/请准时到达会议室?location=31.2304,121.4737&group=工作"
```

#### 设备端行为

1. 收到推送时，通知服务扩展解析 `"31.2304,121.4737"` → 经纬度 `(31.2304, 121.4737)`
2. 自动反地理编码，将格式化地址（如 "上海市黄浦区南京东路"）**拼接到通知正文末尾**
3. 生成地图快照图片（含标记点），作为**通知附件**展示
4. 消息保存时 `location` 存入 `other` JSON 字段
5. 消息卡片底部显示 🗺️ 地图按钮，点击打开 Apple Maps 导航

#### 坐标格式要求

| 规则 | 说明 | 平台差异 |
|------|------|----------|
| 格式 | `纬度,经度`，英文逗号分隔 | apple |
| 纬度范围 | `-90.0` ~ `90.0` | apple |
| 经度范围 | `-180.0` ~ `180.0` | apple |
| 自动纠正 | 如果经纬度位置反了（经度超过 ±90），App 会自动交换顺序 | apple |

#### 支持的模板

| 模板 | 地图按钮 | 平台差异 |
|------|----------|----------|
| `PlainMessageCard` | ✅ 底部显示 🗺️ 地图按钮 | apple |
| `MarkdownMessageCard` | ❌ 不读取 | apple |
| `TerminalMessageCard` | ❌ 不读取 | apple |
| `GitHubMessageCard` | ❌ 不读取 | apple |
| `PaymentMessageCard` | ❌ 不读取 | apple |

---

### 模式二：回调获取模式（Location Push）

传入一个回调 URL，服务端会向设备发送 **Apple Location Push**（静默推送），设备在后台获取当前 GPS 位置后，将坐标 POST 回你的回调 URL。**此模式不会在设备上显示通知**。

#### 前提条件

设备需要先通过 App 注册 Location Push Token。在 App 启动时会自动调用 `startMonitoringLocationPushes` 获取 token 并在注册时上传到服务端（`location` 字段）。

#### 推送示例

```json
{
    "title": "设备位置查询",
    "subtitle": "iOS 设备",
    "body": "获取当前设备所在位置",
    "location": "https://your-server.com/location-callback"
}
```

```sh
# GET 请求
curl "https://wzs.app/your_key?location=https://your-server.com/location-callback&title=设备位置查询&body=获取当前设备所在位置"
```

#### 回调请求

设备获取到位置后，会向 `location` 指定的回调 URL 发送 **POST** 请求：

```json
{
    "title": "设备位置查询",
    "subTitle": "iOS 设备",
    "body": "获取当前设备所在位置",
    "location": "31.2304,121.4737"
}
```

| 回调字段 | 类型 | 说明 | 平台差异 |
|----------|------|------|----------|
| `title` | `String?` | 原始推送请求中的 `title` | apple |
| `subTitle` | `String?` | 原始推送请求中的 `subtitle` | apple |
| `body` | `String?` | 原始推送请求中的 `body` | apple |
| `location` | `String` | 设备当前 GPS 坐标，格式 `"纬度,经度"` | apple |

> **注意**：回调字段名是 `subTitle`（驼峰），与推送 API 的 `subtitle` 不同。

#### 回调重试

设备端最多重试 **3 次**，网络异常时会自动重试直到成功或达到上限。

#### 苹果限制

Location Push 受 Apple 平台限制：

| 限制项 | 说明 | 平台差异 |
|--------|------|----------|
| 频率限制 | 每小时最多 **3 次**，超出会被系统丢弃 | apple |
| 有效期 | Location Push 在 APNs 端保留 **10 分钟** | apple |
| 用户授权 | 设备必须授予「始终允许」位置权限 | apple |
| 低电量模式 | 低电量模式下可能延迟或拒绝 | apple |
| 静默 | 不会显示任何通知，完全静默获取位置 | apple |

---

### 两种模式对比

| | 直接坐标模式 | 回调获取模式 |
|----|----------|----------|
| `location` 值 | `"31.2304,121.4737"` | `"https://your-server.com/callback"` |
| 服务端 PushType | 普通推送 (`1`) | Location Push (`2`) |
| 是否显示通知 | ✅ 显示 | ❌ 静默 |
| 设备端行为 | 显示地图按钮 + 通知附件 | 后台获取 GPS → POST 回调 |
| 地图按钮 | ✅ | ❌（不产生消息卡片） |
| 适用场景 | 告知用户一个已知位置 | 查询设备当前实际位置 |
| 需要 Location Token | ❌ | ✅（App 自动注册） |
| 平台差异 | apple | apple |

---

---

## 模板一览

| style 值 | 模板 | 说明 | 平台差异 |
|----------|------|------|----------|
| 不设置 / 其他 | `PlainMessageCard` | 默认卡片，适合通用通知 | apple |
| `markdown` | `MarkdownMessageCard` | 支持 Markdown 渲染的富文本卡片 | apple |
| `terminal` | `TerminalMessageCard` | 终端命令行风格，适合运维/监控 | apple |
| `github` | `GitHubMessageCard` | GitHub 事件风格，适合代码/CI 通知 | apple |
| `pay` | `PaymentMessageCard` | 支付/账单通知卡片 | apple |

> 鸿蒙端没有上述模板概念：无论 `style` 取何值，统一使用通用卡片并把 `body` 当 Markdown 渲染。

---

## 1. PlainMessageCard（默认）

**触发条件:** `style` 不设置或未匹配到其他模板

![默认卡片结构]

```
┌────────────────────────────┐
│  [图片] (可选)              │
│  ┌──────────────────────┐  │
│  │ 标题         [菜单]  │  │
│  │ 副标题               │  │
│  │                      │  │
│  │ 正文内容 (最多5行)   │  │
│  │ ─────────────────── │  │
│  │ [头像] 群组名 [链接] [地图] │
│  └──────────────────────┘  │
└────────────────────────────┘
```

### 使用的 Message 字段

| 字段 | 用途 | 必填 | 平台差异 |
|------|------|------|----------|
| `title` | 主标题（**headline** 粗体） | - | 全平台 |
| `subtitle` | 副标题（subheadline，含字间距） | - | apple |
| `body` | 正文内容，最多显示 5 行 | ✅ | 全平台 |
| `image` | 顶部大图 | - | 全平台 |
| `icon` | 底部头像 | - | 全平台 |
| `group` | 底部群组名称 | ✅ | 全平台 |
| `url` | 显示 🔗 链接按钮 | - | 全平台 |
| `location` | 坐标 `"lat,lng"` 显示 🗺️ 地图按钮。详见 [📍 Location 定位功能](#-location-定位功能) | - | apple |

### 扩展字段 (`other` JSON)

此模板不读取 `other` JSON。

### 代码示例

```swift
// id, createDate, read 由系统自动生成，无需传入
Message(
    group: "工作",
    title: "项目周报已更新",
    subtitle: "Q3 第一周",
    body: "本周完成了首页重构和搜索优化，详情请查看周报。",
    url: "https://wiki.example.com/weekly",
    ttl: 3600
    // style 不设置，使用默认模板
)
```

**通过推送 API 发送：**

```json
{
    "group": "工作",
    "title": "项目周报已更新",
    "subtitle": "Q3 第一周",
    "body": "本周完成了首页重构和搜索优化，详情请查看周报。",
    "url": "https://wiki.example.com/weekly",
    "ttl": 3600,
    "location": "31.2304,121.4737"
}
```

---

## 2. MarkdownMessageCard（Markdown 卡片）

**触发条件:** `style: "markdown"`

```
┌────────────────────────────────┐
│  标题 [搜索高亮]       [菜单]  │
│  副标题                        │
│  - - - - (虚线分割) - - - -    │
│  [图片] (可选)                 │
│                                │
│  Markdown 渲染正文             │
│  （支持 # ## ### 等语法）      │
│                                │
│  ───────────────────────────── │
│  [头像] 群组名      [🔗链接]   │
│  ════════════════════════════  │
│  (底部彩色状态条)              │
└────────────────────────────────┘
```

### 使用的 Message 字段

| 字段 | 用途 | 必填 | 平台差异 |
|------|------|------|----------|
| `title` | 标题（支持搜索高亮） | - | 全平台 |
| `subtitle` | 副标题（支持搜索高亮） | - | apple |
| `body` | **Markdown 格式**正文 | ✅ | 全平台 |
| `image` | 内嵌图片 | - | 全平台 |
| `icon` | 底部头像 | - | 全平台 |
| `group` | 底部群组名称（受配置 `showGroup` 控制） | ✅ | 全平台 |
| `url` | 显示网络图标按钮，点击用 Safari 打开 | - | 全平台 |

### 无扩展字段

此模板不读取 `other` JSON。

### 代码示例

```swift
// id, createDate, read 由系统自动生成
Message(
    group: "文档",
    title: "伞电(Nolet) 使用指南",
    body: """
    # 快速开始
    ## 安装
    在 App Store 搜索 **Nolet** 下载。
    ## 配置
    1. 打开 App
    2. 扫码绑定设备
    3. 开始接收消息
    """,
    ttl: 86400,
    style: "markdown"
)
```

---

## 3. TerminalMessageCard（终端卡片）

**触发条件:** `style: "terminal"`

```
┌────────────────────────────────┐
│  ● ● ●               [菜单]  ◯│
│  (红黄绿窗口按钮)    (TTL环)   │
│                                │
│  $ 命令标题                    │
│  >> [副标题]                   │
│    ┌──────────────────────┐    │
│    │ 终端输出正文 (灰色背景)│    │
│    └──────────────────────┘    │
│  [图片] (可选)                 │
│                                │
│  [头像] 群组名        [LINK]   │
└────────────────────────────────┘
└─ 外框颜色随 severity 变化 ────┘
```

### 使用的 Message 字段

| 字段 | 用途 | 必填 | 平台差异 |
|------|------|------|----------|
| `title` | 终端命令（显示为 `$ title` 格式） | - | 全平台 |
| `subtitle` | 终端输出前缀（显示为 `>> [subtitle]`） | - | apple |
| `body` | 终端输出正文（灰色代码背景） | ✅ | 全平台 |
| `image` | 图片 | - | 全平台 |
| `icon` | 底部头像 | - | 全平台 |
| `group` | 底部群组名称 | ✅ | 全平台 |
| `url` | 显示 LINK 按钮 | - | 全平台 |

### 扩展字段 (`other` JSON)

| key | 类型 | 可选值 | 说明 | 平台差异 |
|-----|------|--------|------|----------|
| `severity` | `String` | `"success"`（默认绿）、`"warning"`（橙）、`"error"` / `"alert"` / `"system"`（红） | 控制终端 `$` 符号颜色、TTL 环颜色和卡片外框描边颜色 | apple |

### 代码示例

```swift
// id, createDate, read 由系统自动生成
Message(
    group: "服务器",
    title: "生产数据库磁盘过高报警",
    subtitle: "警告：/dev/sda1 剩余空间仅 8.5%",
    body: "收到 Prometheus 警报：宿主机 [Pro-db-04] 当前剩余空间 8.5G/100G，已连续 15 分钟呈递增趋势，请尽快处理。",
    url: "https://grafana.example.com/alerts",
    ttl: 600,
    style: "terminal",
    other: """
        { "severity": "warning" }
        """
)
```

---

## 4. GitHubMessageCard（GitHub 事件卡片）

**触发条件:** `style: "github"`

```
┌──────────────────────────────────────┐
│ ▓ │ 📁 GITHUB/REPO • 群组名  [菜单][◯]│
│   │ [severity] [分支名] [来源主机]    │
│   │                                  │
│   │ 标题 (PR/MR 标题)                │
│   │ 副标题 (描述)                    │
│   │  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐    │
│   │  │ 正文内容 (代码/日志等)    │  │
│   │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘    │
│   │ 底部备注              [LINK]     │
└──────────────────────────────────────┘
  ↑ 左侧竖条颜色随 severity 变化
```

### 使用的 Message 字段

| 字段 | 用途 | 必填 | 平台差异 |
|------|------|------|----------|
| `title` | PR/Commit 标题 | - | 全平台 |
| `subtitle` | 描述/摘要 | - | apple |
| `body` | 正文内容（代码 diff、日志等），灰色背景显示 | - | 全平台 |
| `group` | 群组名，显示在 header 右侧 | ✅ | 全平台 |
| `url` | 显示 LINK 按钮 | - | 全平台 |

### 扩展字段 (`other` JSON)

| key | 类型 | 默认值 | 说明 | 平台差异 |
|-----|------|--------|------|----------|
| `severity` | `String` | `"EVENT"` | 严重等级，控制左侧竖条和标签颜色：`"INFO"`（蓝）、`"SUCCESS"`（绿）、`"WARN"`（橙）、`"CRIT"`（红） | apple |
| `header` | `String` | `"GITHUB"` | 顶部左侧标题（例如 `"GITHUB/REPO"`） | apple |
| `branch` | `String` | `"main"` | 分支名，显示为标签（例如 `"main <- jwt-auth"`） | apple |
| `from` | `String` | - | 来源 URL，自动提取并显示 host | apple |
| `footer` | `String` | - | 底部备注文字（等宽字体，例如 `"SHA:abc123"`） | apple |

### 代码示例

```swift
// id, createDate, read 由系统自动生成
Message(
    group: "主机通知",
    title: "Merge pull request #157 from feature/jwt-auth",
    subtitle: "实现了符合 OAuth2 规范的 JWT 核心安全鉴权",
    body: "支持自动令牌刷新与设备白名单校验。",
    url: "https://github.com/apple/swift",
    ttl: 600,
    style: "github",
    other: """
        {
            "header": "GITHUB/REPO",
            "severity": "SUCCESS",
            "branch": "main <- jwt-auth",
            "from": "https://api.github.com",
            "footer": "SHA:abc123def456"
        }
        """
)
```

---

## 5. PaymentMessageCard（支付卡片）

**触发条件:** `style: "pay"`

```
┌────────────────────────────────┐
│  [头像] 标题           [菜单]  │
│                                │
│  正文描述          金额/副标题  │
│  (商户信息)       (金额大字)    │
│                                │
│  订单号: XXXX (可选)           │
│                                │
│  ████████████████░░░░  ← TTL 进度条
└────────────────────────────────┘
```

### 使用的 Message 字段

| 字段 | 用途 | 必填 | 平台差异 |
|------|------|------|----------|
| `title` | 通知标题（如 "支付确认"、"收款通知"） | - | 全平台 |
| `subtitle` | **金额**，大字显示在右侧（如 `"-¥6,799.00"`），颜色随平台变化 | - | apple |
| `body` | 商户/交易描述 | ✅ | 全平台 |
| `icon` | 平台图标 URL（建议使用 favicon） | - | 全平台 |
| `group` | **支付平台标识**，决定品牌色（见下方支持列表） | ✅ | 全平台 |
| `url` | "打开链接" 按钮 | - | 全平台 |
| `ttl` | 存活时长，底部 TTL 进度条倒计时 | ✅ | 全平台 |

### 扩展字段 (`other` JSON)

| key | 类型 | 说明 | 平台差异 |
|-----|------|------|----------|
| `ticket` | `String` | 订单号 / 票据号码，显示在卡片中段 | apple |

### `group` 支持的支付平台

| 值 | 平台 | 品牌色 | 平台差异 |
|----|------|--------|----------|
| `alipay` / `支付宝` | 支付宝 | 蓝 `#128EFA` | apple |
| `wechat` / `wechat pay` / `微信支付` | 微信支付 | 绿 `#07C160` | apple |
| `paypal` | PayPal | 深蓝 `#003087` | apple |
| `stripe` | Stripe | 紫蓝 `#635BFF` | apple |
| `applepay` / `apple pay` | Apple Pay | 系统 primary | apple |
| `googlepay` / `google pay` | Google Pay | 蓝 `#4285F4` | apple |
| `visa` | Visa | 深蓝 `#1A1F71` | apple |
| `mastercard` / `master` | Mastercard | 橙 `#FF5F00` | apple |
| `amex` / `american express` | American Express | 蓝 `#016FD0` | apple |
| `unionpay` / `银联` | 中国银联 | 青 `#00796B` | apple |
| `linepay` / `line pay` | LINE Pay | 绿 `#06C755` | apple |
| `klarna` | Klarna | 粉 `#FFB3C7` | apple |
| `paytm` | Paytm | 浅蓝 `#00BAF2` | apple |
| `discover` | Discover | 橙 `#E55C20` | apple |
| `jcb` | JCB | 深蓝 `#00377B` | apple |
| `samsungpay` / `samsung pay` | Samsung Pay | 蓝 `#1428A0` | apple |
| `ideal` | iDEAL | 玫红 `#CC0066` | apple |
| `bancontact` | Bancontact | 黑 `#000000` | apple |
| `giropay` | Giropay | 蓝 `#005A9B` | apple |
| 其他值 | 自定义 | 紫色兜底 | apple |

### 代码示例

```swift
// 支付宝扣款通知 (id, createDate, read 由系统自动生成)
Message(
    group: "alipay",
    title: "支付确认",
    subtitle: "-¥6,799.00",
    body: "您正在【Apple Store】消费，请确认扣款。",
    icon: "https://favicon.wzs.app/alipay.com",
    ttl: 600,
    style: "pay"
)

// 微信收款通知（带订单号）
Message(
    group: "wechat",
    title: "收款通知",
    subtitle: "+¥18.50",
    body: "二维码收款已到账",
    icon: "https://favicon.wzs.app/wechat.com",
    ttl: 600,
    style: "pay",
    other: """
        { "ticket": "订单号: 2024072420001" }
        """
)
```

---

## 模板选择机制

在 `TemplateHandler.swift` 中，`MessageCardView` 根据 `message.style` 字段自动选择模板：

```swift
switch message.style?.lowercased() {
case "markdown":  MarkdownMessageCard(...)
case "terminal":  TerminalMessageCard(...)
case "github":    GitHubMessageCard(...)
case "pay":       PaymentMessageCard(...)
default:          PlainMessageCard(...)
}
```

如果 `style` 未设置或值不匹配任何已知模板，默认使用 `PlainMessageCard`。平台差异：apple（鸿蒙端无此选择逻辑，统一渲染 Markdown）。

---

## 通用交互功能

所有模板共享以下交互（由 `MessageInteractiveModifier` 统一注入）：

| 交互 | 操作 | 平台差异 |
|------|------|----------|
| **双击** | 全屏查看消息详情 | apple |
| **点击时间** | 点击卡片上的相对时间（如"刚刚"、"5分钟前"）弹出操作菜单：复制内容、分享截图、分享图片、分享文字、回复、智能助手、删除 | apple |
| **TTL** | 消息到期自动消失，卡片中显示环形或条形倒计时 | 全平台（倒计时控件形态不同） |
| **回复** | 若 `reply` 字段有值，底部出现回复输入框 | apple |
| **截图分享** | 可生成卡片截图用于分享 | apple |

> 鸿蒙端通用卡片支持：正文超 5 行截断并显示「查看更多」、未读竖条呼吸、点击 url 行跳转、同 id 覆盖刷新。
