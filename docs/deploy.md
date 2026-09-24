# 部署服务

本文介绍如何部署伞电(Nolet) 服务端 **Nolets**，以及服务端的接口与参数。Nolets 同时支持 **Apple APNs** 与 **鸿蒙 HarmonyOS Push Kit**，推送时按用户设备的系统类型自动分流。

> **平台差异标签说明**：下文所有参数都在末尾用标签标注其生效平台，取值为
> `全平台`（Apple 与鸿蒙通用）、`apple`（仅苹果设备/APNs 相关）、`harmony`（仅鸿蒙设备/Push Kit 相关）。

---

## 一键安装（推荐）

Linux / macOS（需已安装 Docker，Linux 未安装时脚本会自动安装 Docker）：

```bash
curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh | bash
```

脚本会：

1. 检查 / 安装 Docker（macOS 请先自行安装 Docker Desktop）
2. 在工作目录写入 `compose.yaml`（Linux 默认 `/opt/nolet`，macOS 默认 `~/.nolet`）
3. 拉取 `ghcr.io/sunvc/nolets:latest` 并通过 `docker compose` 启动容器 `NoLets`
4. 轮询 `http://127.0.0.1:8080/health` 做健康检查

### 常用示例

```bash
# 自定义安装目录、端口，并注入签名密钥与授权 ID 列表
curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh | bash -s -- \
    --dir /opt/nolet \
    --port 8080 \
    --sign-key "your-sign-key" \
    --auths '["uid1","uid2"]'

# 通过环境变量传参
NOLET_PORT=9090 NOLET_SIGN_KEY=xxx TZ=Asia/Shanghai \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh)"

# 卸载（仅移除容器，保留数据目录）
curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh | bash -s -- --uninstall
```

### 安装脚本参数

| 参数 | 环境变量 | 说明 | 默认值 | 平台差异 |
|------|----------|------|--------|----------|
| `--dir` | `NOLET_DIR` | 工作目录（compose.yaml 与 data 存放位置） | Linux `/opt/nolet` · macOS `~/.nolet` | 全平台 |
| `--port` | `NOLET_PORT` | 宿主机映射端口 | `8080` | 全平台 |
| `--image` | `NOLET_IMAGE` | Docker 镜像 | `ghcr.io/sunvc/nolets:latest` | 全平台 |
| `--sign-key` | `NOLET_SIGN_KEY` | 应用签名密钥 |  | 全平台 |
| `--auths` | `NOLET_AUTHS` | 管理员 ID 列表，如 `'["uid1","uid2"]'` |  | 全平台 |
| `--tz` | `TZ` | 时区 | `Asia/Shanghai` | 全平台 |
| `--name` | `NOLET_CONTAINER` | 容器名 | `NoLets` | 全平台 |
| `--uninstall` |  | 移除容器 |  | 全平台 |

### 常用运维命令

```bash
docker logs -f NoLets                                          # 查看日志
docker restart NoLets                                          # 重启
cd /opt/nolet && docker compose pull && docker compose up -d   # 更新到最新镜像
```

---

## Docker 部署

镜像地址：

- Docker Hub：`sunvc/nolets:latest`
- GitHub Container Registry：`ghcr.io/sunvc/nolets:latest`

```shell
docker run -d --name NoLets -p 8080:8080 \
  -v ./data:/data --restart=always \
  ghcr.io/sunvc/nolets:latest
```

## Docker Compose 部署

Nolets 仓库内置了 `deploy/compose.yaml` 与示例配置，可直接复制到服务器后启动：

```yaml
services:
  NoLetServer:
    image: ghcr.io/sunvc/nolets:latest
    container_name: NoLets
    restart: always
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
```

`config.yaml` 为可选项，仅在需要自定义配置时才创建并通过 `--config` 指定。启动：

```shell
docker compose up -d
```

## 二进制 / 手动部署

可从 [GitHub Releases](https://github.com/sunvc/NoLetserver/releases) 下载预编译二进制（Windows、macOS、Linux、FreeBSD 多架构），或从 [Nolets 仓库](https://github.com/sunvc/NoLets)自行编译：

```sh
./NoLets --config /path/to/config.yaml
```

---

## 配置文件

项目中的 `config.yaml` 仅作示例，**用户需要自己创建并指定配置文件**，用 `--config` / `-c` 指定路径。

### 配置文件结构

```yaml
system:
  user: ""                         # 基础认证用户名
  password: ""                     # 基础认证密码
  push_password: ""                # 群组推送密码
  addr: "0.0.0.0:8080"             # 服务器监听地址
  url_prefix: "/"                  # 服务 URL 前缀
  data: "./data"                   # 数据存储目录
  name: "NoLets"                   # 服务名称
  dsn: ""                          # MySQL DSN 连接字符串
  cert: ""                         # TLS 证书路径
  key: ""                          # TLS 证书私钥路径
  sign_key: ""                     # App 注册签名密钥
  reduce_memory_usage: false       # 降低内存占用（增加 CPU 消耗）
  proxy_header: ""                 # HTTP 头中远程 IP 地址来源
  max_batch_push_count: -1         # 批量推送最大数量，-1 表示无限制
  max_apns_client_count: 1         # 最大 APNs 客户端连接数
  max_device_key_arr_length: 10    # 最大设备 Key 列表数量
  concurrency: 262144              # 最大并发连接数（256 * 1024）
  read_timeout: 3s                 # 读取超时时间
  write_timeout: 3s                # 写入超时时间
  idle_timeout: 10s                # 空闲超时时间
  admins: []                       # 管理员 ID 列表
  debug: false                     # 启用调试模式
  expired: 0                       # 语音过期时间（秒）
  icp_info: ""                     # ICP 备案信息
  time_zone: "UTC"                 # 时区设置
  voice: false                     # 启用语音支持
  auths: []                        # 授权 ID 列表

apple:
  apnsPrivateKey: ""               # APNs 私钥内容或路径
  topic: ""                        # APNs Topic
  keyID: ""                        # APNs Key ID
  teamID: ""                       # APNs Team ID
  develop: false                   # 启用 APNs 开发环境

harmony:
  project_id: ""                   # 鸿蒙 AGC 项目 ID（推送 URL 使用）
  key_id: ""                       # 服务账号 Key ID（JWT kid）
  private_key: ""                  # 服务账号 RSA 私钥（PEM 内容，需真实换行）
  sub_account: ""                  # 服务账号/子账号（JWT iss）
  client_id: ""                    # 应用 Client ID（撤销推送时使用）
  auth_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/authorize"
  token_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/token"
  auth_provider_cert_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/certs"
  client_cert_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/x509?client_id="
  develop: false                   # 鸿蒙测试推送
```

---

## 命令行参数与环境变量

### 系统 / 通用参数

| 参数 | 环境变量 | 说明 | 默认值 | 平台差异 |
|------|----------|------|--------|----------|
| `--addr` | `NOLET_SERVER_ADDRESS` | 服务器监听地址 | `0.0.0.0:8080` | 全平台 |
| `--url-prefix` | `NOLET_SERVER_URL_PREFIX` | 服务 URL 前缀 | `/` | 全平台 |
| `--dir` | `NOLET_SERVER_DATA_DIR` | 数据存储目录 | `./data` | 全平台 |
| `--dsn` | `NOLET_SERVER_DSN` | MySQL DSN，格式 `user:pass@tcp(host)/dbname` |  | 全平台 |
| `--cert` | `NOLET_SERVER_CERT` | TLS 证书路径 |  | 全平台 |
| `--key` | `NOLET_SERVER_KEY` | TLS 证书私钥路径 |  | 全平台 |
| `--reduce-memory-usage` | `NOLET_SERVER_REDUCE_MEMORY_USAGE` | 降低内存占用（增加 CPU 消耗） | `false` | 全平台 |
| `--user, -u` | `NOLET_SERVER_BASIC_AUTH_USER` | 基础认证用户名 |  | 全平台 |
| `--password, -p` | `NOLET_SERVER_BASIC_AUTH_PASSWORD` | 基础认证密码 |  | 全平台 |
| `--push-password` | `NOLET_PUSH_PASSWORD` | 群组推送认证密码 |  | 全平台 |
| `--sign-key, --sk` | `NOLET_SIGN_KEY` | App 注册签名密钥 |  | 全平台 |
| `--proxy-header` | `NOLET_SERVER_PROXY_HEADER` | 代理头中远程 IP 地址字段 |  | 全平台 |
| `--max-batch-push-count` | `NOLET_SERVER_MAX_BATCH_PUSH_COUNT` | 最大批量推送数量，`-1` 表示无限制 | `-1` | 全平台 |
| `--max-apns-client-count, --max` | `NOLET_SERVER_MAX_APNS_CLIENT_COUNT` | 最大 APNs 客户端连接数 | `1` | apple |
| `--max-device-key-arr-length` | `NOLET_CONCURRENCY` | 单次请求允许的最大设备 Key 数 | `10` | 全平台 |
| `--concurrency` | `NOLET_SERVER_CONCURRENCY` | 最大并发连接数 | `262144` | 全平台 |
| `--read-timeout` | `NOLET_SERVER_READ_TIMEOUT` | 读取请求超时时间 | `3s` | 全平台 |
| `--write-timeout` | `NOLET_SERVER_WRITE_TIMEOUT` | 响应写入超时时间 | `3s` | 全平台 |
| `--idle-timeout` | `NOLET_SERVER_IDLE_TIMEOUT` | Keep-Alive 空闲超时时间 | `10s` | 全平台 |
| `--debug` | `NOLET_DEBUG` | 启用调试模式 | `false` | 全平台 |
| `--voice` | `NOLET_VOICE` | 启用语音支持 | `false` | 全平台 |
| `--auths` | `NOLET_AUTHS` | 授权设备 / 管理员 ID 列表 |  | 全平台 |
| `--Expired, --ex` | `NOLET_EXPIRED_TIME` | 语音过期时间（秒） | `120` | 全平台 |
| `--ICP, --icp` | `NOLET_ICP_INFO` | ICP 备案信息 |  | 全平台 |
| `--proxy-download, --dp` | `NOLET_PROXY_DOWNLOAD` | 启用代理下载 | `false` | 全平台 |
| `--export-path, --dc` | `NOLET_EXPORT_PATH` | 导出数据库路径 |  | 全平台 |
| `--import-path, --dl` | `NOLET_IMPORT_PATH` | 导入数据库路径 |  | 全平台 |
| `--build-test` |  | 构建测试模式 |  | 全平台 |
| `--config, -c` |  | 配置文件路径 |  | 全平台 |
| `--help, -h` |  | 显示帮助信息 |  | 全平台 |

### Apple APNs 参数

| 参数 | 环境变量 | 说明 | 默认值 | 平台差异 |
|------|----------|------|--------|----------|
| `--apns-private-key` | `NOLET_APPLE_APNS_PRIVATE_KEY` | APNs 私钥路径或内容 | 内置默认值 | apple |
| `--topic` | `NOLET_APPLE_TOPIC` | APNs Topic | `me.uuneo.Meoworld` | apple |
| `--key-id` | `NOLET_APPLE_KEY_ID` | APNs Key ID | `BNY5GUGV38` | apple |
| `--team-id` | `NOLET_APPLE_TEAM_ID` | APNs Team ID | `FUWV6U942Q` | apple |
| `--develop, --dev` | `NOLET_APPLE_DEVELOP` | 使用 APNs 开发环境 | `false` | apple |

### 鸿蒙 Push Kit 参数

| 参数 | 环境变量 | 说明 | 默认值 | 平台差异 |
|------|----------|------|--------|----------|
| `--hm-project-id` | `NOLET_HM_PROJECT_ID` | 鸿蒙 AGC 项目 ID（推送 URL 使用） |  | harmony |
| `--hm-key-id` | `NOLET_HM_KEY_ID` | 鸿蒙服务账号 Key ID（JWT kid） |  | harmony |
| `--hm-private-key` | `NOLET_HM_PRIVATE_KEY` | 鸿蒙服务账号 RSA 私钥（PEM 内容，需真实换行） |  | harmony |
| `--hm-sub-account` | `NOLET_HM_SUB_ACCOUNT` | 鸿蒙服务账号/子账号（JWT iss） |  | harmony |
| `--hm-client-id` | `NOLET_HM_CLIENT_ID` | 鸿蒙应用 Client ID（撤销推送时使用） |  | harmony |
| `--hm-auth-uri` | `NOLET_HM_AUTH_URI` | 鸿蒙 OAuth 授权地址 | `https://oauth-login.cloud.huawei.com/oauth2/v3/authorize` | harmony |
| `--hm-token-uri` | `NOLET_HM_TOKEN_URI` | 鸿蒙 OAuth Token 地址（JWT aud） | `https://oauth-login.cloud.huawei.com/oauth2/v3/token` | harmony |
| `--hm-auth-provider-cert-uri` | `NOLET_HM_AUTH_PROVIDER_CERT_URI` | 鸿蒙授权方证书地址 | `https://oauth-login.cloud.huawei.com/oauth2/v3/certs` | harmony |
| `--hm-client-cert-uri` | `NOLET_HM_CLIENT_CERT_URI` | 鸿蒙客户端证书地址 | `https://oauth-login.cloud.huawei.com/oauth2/v3/x509?client_id=` | harmony |
| `--hm-develop` | `NOLET_HM_DEVELOP` | 鸿蒙测试推送 | `false` | harmony |

### 配置优先级

- 使用 `-c` / `--config` 时：**配置文件 > 命令行参数 > 环境变量**。配置文件中写出的键（即使值为空字符串）优先级最高，会覆盖命令行与环境变量。
- 不使用 `-c` 时：**命令行参数 > 环境变量 > 内置默认值**。

---

## 鸿蒙推送（HarmonyOS Push Kit）

除 Apple APNs 外，服务端同时支持 HarmonyOS Push Kit。推送时按用户设备的 OS 类型自动分流，无需额外开关，配置好鸿蒙凭据即可。

### 认证流程

1. 使用服务账号的 RSA 私钥以 **PS256** 算法签名 JWT：`kid` 为 Key ID，`iss` 为子账号，`aud` 为 Token URI，有效期 1 小时（程序会缓存并提前刷新）；
2. 普通推送调用 `https://push-api.cloud.huawei.com/v3/{项目ID}/messages:send`，请求头携带 `Authorization: Bearer <JWT>`；
3. 后台静默推送（无通知内容）调用 `messages:revoke` 撤销消息，此时 URL 中使用 **Client ID**。

### 凭据获取（AppGallery Connect）

| 配置项 | 获取位置 | 平台差异 |
|--------|----------|----------|
| 项目 ID `project_id` | AGC →「项目设置」→「常规」→ 项目 ID | harmony |
| Client ID `client_id` | AGC →「项目设置」→「常规」→ 应用信息 → Client ID | harmony |
| Key ID `key_id` | AGC →「用户与访问」→「服务账号」→ 创建/查看密钥 | harmony |
| 私钥 `private_key` | 创建服务账号密钥时下载的 PEM 文件内容 | harmony |
| 子账号 `sub_account` | AGC →「用户与访问」→「服务账号」中对应账号 | harmony |

### 注意事项

- **私钥换行**：PEM 必须包含真实换行。通过环境变量注入时使用单引号并直接粘贴多行内容；写在双引号里的 `\n` 不会被 shell 转义，程序收到的是字面的反斜杠加 n，会导致 PEM 解析失败。
- **环境变量大小写**：测试推送开关变量为全大写的 `NOLET_HM_DEVELOP`，Linux 下环境变量大小写敏感。
- **与配置文件同时使用**：`-c` 指定的配置文件中 harmony 段写出的键（包括空字符串）会覆盖同名环境变量；若希望完全由环境变量配置，请勿使用 `-c`。
- **测试推送**：开启 `--hm-develop` 或系统 `--debug` 后，推送请求会以测试消息（`TestMessage`）发送。平台差异：harmony。

---

## 服务接口

### 基础接口

| 接口 | 说明 | 平台差异 |
|------|------|----------|
| `GET /ping` | 连通性检查 | 全平台 |
| `GET /health` / `GET /healthz` | 健康检查 | 全平台 |
| `GET /info` | 服务信息与监控信息 | 全平台 |
| `POST /register` | 注册 / 更新设备 | 全平台 |
| `GET /register/:deviceKey` | 校验或恢复设备 Key | 全平台 |
| `POST /push` | 标准 JSON / Form 推送 | 全平台 |
| `POST /ptt/connect` | 建立 PTT 语音连接 | apple |
| `POST /ptt/voice` | 上传或发送 PTT 语音 | apple |
| `GET /ptt/voice/:name` | 获取 PTT 语音文件 | apple |

### 统一响应

服务端统一返回 JSON：

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "trace": "trace-id",
  "timestamp": 1720000000
}
```

注意：Nolets 的很多失败情况仍然返回 HTTP 200，真正的业务状态请以 JSON 中的 `code` 和 `message` 为准。

---

## 注册接口

### `POST /register`

请求体字段：

| 字段 | 说明 | 平台差异 |
|------|------|----------|
| `key` | 设备 Key，可为空；为空时服务端自动生成 | 全平台 |
| `token` | 普通推送 Token | 全平台 |
| `talk` | PushToTalk 通话 Token | apple |
| `location` | 位置推送 Token（Location Push） | apple |
| `group` | 设备分组，可为空 | 全平台 |

返回的 `data` 与统一响应一致，并额外包含 `core=2`。

### `GET /register/:deviceKey`

用于校验或恢复已有设备 Key：

| 场景 | 行为 |
|------|------|
| Key 已存在 | 返回成功 |
| Key 不存在且当前请求是管理员 | 创建空记录后返回成功 |
| Key 不存在且不是管理员 | 返回错误 |

### 鉴权规则

`/register` 与 `/register/:deviceKey` 都会经过签名校验中间件：

| 条件 | 说明 |
|------|------|
| 管理员请求 | 可跳过签名校验 |
| 非管理员请求 | `User-Agent` 必须以 `NoLet` 开头 |
| 配置了 `sign_key` | 必须额外提供 `Authorization` 或 `X-Signature` |
| 签名内容 | 解密后必须是时间戳，且与服务端时间差不超过 10 秒 |

---

## 推送接口

### 支持的入口

| 接口 | 说明 |
|------|------|
| `POST /push` | 标准 JSON / Form 推送 |
| `GET /:deviceKey` | 参数化推送或查询注册信息 |
| `POST /:deviceKey` | 参数化推送 |
| `GET/POST /:deviceKey/:body` | 路径 body 推送 |
| `GET/POST /:deviceKey/:title/:body` | 路径 title + body 推送 |
| `GET/POST /:deviceKey/:title/:subtitle/:body` | 路径 title + subtitle + body 推送 |

> 路径中的 `subtitle` 仅对 Apple 设备生效；鸿蒙会忽略该字段。平台差异：apple。

### 参数来源

服务端同时解析以下输入并统一做字段归一化：

| 来源 | 说明 |
|------|------|
| 路径参数 | 适合快速拼接 URL 调用 |
| Query 参数 | 适合 GET 请求 |
| `application/json` | 适合标准 API 接入 |
| Form 表单 | 适合传统 Web 表单 |

字段名会先去掉符号与空格，再转成小写字母数字，因此 `deviceKey`、`device-key`、`device_key` 会被视为同一个字段。

### 常用字段

| 字段 | 说明 | 平台差异 |
|------|------|----------|
| `devicekey` | 单个设备 Key，支持逗号分隔多个值 | 全平台 |
| `devicekeys` | 设备 Key 数组 | 全平台 |
| `devicetoken` | 直接使用推送 Token 发送 | 全平台 |
| `title` | 通知标题 | 全平台 |
| `subtitle` | 通知副标题 | apple |
| `body` | 通知正文（兼容 content / message / data / text 别名） | 全平台 |
| `markdown` / `md` | Markdown 正文，强制 `category=markdown` | 全平台 |
| `sound` | 声音名称；不带扩展名时服务端为 Apple 自动补 `.caf`。鸿蒙端从应用内置 rawfile 读取同名 `.mp3` | 全平台 |
| `category` | 通知分类，仅支持 `myNotificationCategory` / `markdown` 或 `alfa`…`zulu` | apple |
| `level` | 中断级别 passive / active / timeSensitive / critical | apple |
| `volume` | critical 音量 0…10 | apple |
| `badge` | 角标数字，`<=0` 清零 | 全平台 |
| `call` | 持续响铃。Apple：`1` 循环铃声约 30 秒 / http URL 下载音频 / 文本走 TTS。鸿蒙：数字 `10`…`60` 表示铃声播放时长（秒） | 全平台 |
| `url` | 点击跳转链接 | 全平台 |
| `icon` | 发送者图标 URL（URL 形式） | 全平台 |
| `image` | 图片附件 URL | 全平台 |
| `copy` | 指定「复制」动作复制的文本 | 全平台 |
| `autocopy` | 自动复制开关，默认 `0` | apple |
| `savealbum` | 是否把图片存入系统相册 | apple |
| `id` | 消息 ID；未传时自动生成 UUID | 全平台 |
| `group` | APNs `thread-id`，也可作为设备分组字段 | 全平台 |
| `location` | 坐标 `"lat,lng"` 显示地图按钮，或回调 URL 触发 Location Push | apple |
| `pushgroupname` | 管理员按设备分组批量推送 | 全平台 |
| `ciphertext` | 加密推送密文（base64） | 全平台 |
| `ciphernumber` | 解密密钥在密钥列表中的序号，默认 `0` | 全平台 |
| `script` | 后台处理器脚本名 | apple |
| `plugin` | 通知插件脚本名 | apple |

### 兼容别名与默认值

| 规则 | 说明 | 平台差异 |
|------|------|----------|
| `data` / `content` / `message` / `text` | 自动映射到 `body` | 全平台 |
| `markdown` / `md` | 自动映射到 `body`，并强制 `category=markdown` | 全平台 |
| `autocopy` | 默认值为 `0` | apple |
| `level` | 默认值为 `active` | apple |
| `category` | 默认值为 `myNotificationCategory` | apple |

### 推送模式

| 模式 | 触发条件 | 平台差异 |
|------|----------|----------|
| 普通通知 | 存在 `title`、`subtitle`、`body`、`ciphertext`、`image` 中任一内容字段 | 全平台 |
| 定位推送 | `location` 为合法 URL（有 scheme + host） | apple |
| 地图坐标 | `location` 为 `"纬度,经度"` 坐标，随普通通知下发并显示地图按钮 | apple |
| 静默推送 | 没有内容字段，但存在 `id` | 全平台 |
| 查询模式 | 没有内容字段且没有 `id`，此时返回设备注册信息而不是发推送 | 全平台 |

### 注销语义

更新已有注册记录时，如果 `token` 长度小于 `64` 且 `group` 与原记录一致，服务端会直接删除该设备记录，可视为注销或清空注册。

---

## 其他资料

服务端代码：<a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a>
App 代码：<a href='https://github.com/sunvc/NoLet'>https://github.com/sunvc/NoLet>

当你需要把伞电(Nolet) 集成到自己的系统、或重新实现后端时可能用到 APNs 推送证书（仅 Apple 平台需要，平台差异：apple）：

- Key ID：`BNY5GUGV38`
- Team ID：`FUWV6U942Q`
- 下载地址：[AuthKey.p8](https://s3.wzs.app/AuthKey_BNY5GUGV38_FUWV6U942Q.p8)
