# Docker-Compose

* 配置文件(不是必须, 只在大量自定义情况使用)

```yaml
system:
  user: ""
  password: ""
  push_password: ""
  addr: "0.0.0.0:8080"
  url_prefix: ""
  data: "./data"
  name: "NoLets"
  dsn: ""
  cert: ""
  key: ""
  sign_key: ""
  reduce_memory_usage: false
  proxy_header: ""
  max_batch_push_count: -1
  max_apns_client_count: 1
  max_device_key_arr_length: 10
  concurrency: 262144   # 256 * 1024
  read_timeout: 3s
  write_timeout: 3s
  idle_timeout: 10s
  admins: []
  debug: false
  version: ""
  build_date: ""
  commitID: ""
  expired: 0
  icp_info: ""
  time_zone: "UTC"
  voice: false
  auths: []

apple:
  apnsPrivateKey: ""
  topic: ""
  keyID: ""
  teamID: ""
  develop: false


```

## 命令行参数

除了配置文件外，还可以通过命令行参数或环境变量来配置服务：

| 参数 | 环境变量 | 说明 | 默认值 |
|------|----------|------|--------|
| `--addr` | `NOLET_SERVER_ADDRESS` | 服务器监听地址 | `0.0.0.0:8080` |
| `--url-prefix` | `NOLET_SERVER_URL_PREFIX` | 服务 URL 前缀 | `/` |
| `--dir` | `NOLET_SERVER_DATA_DIR` | 数据存储目录 | `./data` |
| `--dsn` | `NOLET_SERVER_DSN` | MySQL DSN，格式：`user:pass@tcp(host)/dbname` | 空 |
| `--cert` | `NOLET_SERVER_CERT` | TLS 证书路径 | 空 |
| `--key` | `NOLET_SERVER_KEY` | TLS 证书私钥路径 | 空 |
| `--reduce-memory-usage` | `NOLET_SERVER_REDUCE_MEMORY_USAGE` | 降低内存占用（增加 CPU 消耗） | `false` |
| `--user, -u` | `NOLET_SERVER_BASIC_AUTH_USER` | 基础认证用户名 | 空 |
| `--password, -p` | `NOLET_SERVER_BASIC_AUTH_PASSWORD` | 基础认证密码 | 空 |
| `--push-password` | `NOLET_PUSH_PASSWORD` | 推送认证密码 | 空 |
| `--sign-key, --sk` | `NOLET_SIGN_KEY` | App 注册签名密钥 | 空 |
| `--proxy-header` | `NOLET_SERVER_PROXY_HEADER` | HTTP 头中远程 IP 地址来源 | 空 |
| `--max-batch-push-count` | `NOLET_SERVER_MAX_BATCH_PUSH_COUNT` | 批量推送最大数量，`-1` 表示无限制 | `-1` |
| `--max-apns-client-count, --max` | `NOLET_SERVER_MAX_APNS_CLIENT_COUNT` | 最大 APNs 客户端连接数 | `1` |
| `--max-device-key-arr-length` | `NOLET_CONCURRENCY` | 单次请求允许的最大设备 Key 数 | `10` |
| `--concurrency` | `NOLET_SERVER_CONCURRENCY` | 最大并发连接数 | `262144` |
| `--read-timeout` | `NOLET_SERVER_READ_TIMEOUT` | 读取请求超时时间 | `3s` |
| `--write-timeout` | `NOLET_SERVER_WRITE_TIMEOUT` | 响应写入超时时间 | `3s` |
| `--idle-timeout` | `NOLET_SERVER_IDLE_TIMEOUT` | Keep-Alive 空闲超时时间 | `10s` |
| `--debug` | `NOLET_DEBUG` | 启用调试模式 | `false` |
| `--voice` | `NOLET_VOICE` | 启用语音支持 | `false` |
| `--auths` | `NOLET_AUTHS` | 授权设备 ID 列表 | 空 |
| `--apns-private-key` | `NOLET_APPLE_APNS_PRIVATE_KEY` | APNs 私钥路径 | 内置默认值 |
| `--topic` | `NOLET_APPLE_TOPIC` | APNs Topic | `me.uuneo.Meoworld` |
| `--key-id` | `NOLET_APPLE_KEY_ID` | APNs Key ID | `BNY5GUGV38` |
| `--team-id` | `NOLET_APPLE_TEAM_ID` | APNs Team ID | `FUWV6U942Q` |
| `--develop, --dev` | `NOLET_APPLE_DEVELOP` | 启用 APNs 开发环境 | `false` |
| `--Expired, --ex` | `NOLET_EXPIRED_TIME` | 语音过期时间（秒） | `120` |
| `--ICP, --icp` | `NOLET_ICP_INFO` | ICP 备案信息 | 空 |
| `--proxy-download, --dp` | `NOLET_PROXY_DOWNLOAD` | 启用代理下载 | `false` |
| `--export-path, --dc` | `NOLET_EXPORT_PATH` | 导出数据库路径 | 空 |
| `--import-path, --dl` | `NOLET_IMPORT_PATH` | 导入数据库路径 | 空 |
| `--help, -h` | - | 显示帮助信息 | - |
| `--config, -c` | - | 指定配置文件路径 | - |

命令行参数优先级高于配置文件，环境变量优先级高于命令行参数。

## Docker部署

```shell

docker run -d --name NoLets -p 8080:8080 -v ./data:/data --restart=always ghcr.io/sunvc/nolet:latest
```

## Docker-compose部署

* `NoLets` 仓库内置了 `deploy/compose.yaml` 与示例 `config.yaml`，可直接复制到服务器后启动。
* `config.yaml` 为可选项，只有在需要自定义配置时才需要创建并通过 `--config` 指定。

* 启动

```shell
docker-compose up -d
```

## 手动部署

1. 根据平台下载可执行文件或自己编译:<br>
<a href="https://github.com/sunvc/NoLets">NoLets</a>

2. 使用配置文件运行
---

```sh
./NoLets --config /path/to/config.yaml
```

## 服务接口

### 基础接口

| 接口 | 说明 |
|------|------|
| `GET /ping` | 连通性检查 |
| `GET /health` / `GET /healthz` | 健康检查 |
| `GET /info` | 服务信息与监控信息 |
| `POST /ptt/connect` | 建立 PTT 连接 |
| `POST /ptt/voice` | 上传或发送 PTT 语音 |
| `GET /ptt/voice/:name` | 获取 PTT 语音文件 |

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

注意：`NoLets` 的很多失败情况仍然返回 HTTP 200，真正的业务状态请以 JSON 中的 `code` 和 `message` 为准。

## 注册接口

### `POST /register`

请求体字段如下：

| 字段 | 说明 |
|------|------|
| `key` | 设备 Key，可为空；为空时服务端自动生成 |
| `token` | 普通推送 Token |
| `talk` | PushToTalk Token |
| `location` | 位置 Push Token |
| `group` | 设备分组，可为空 |

返回的 `data` 结构与上表一致，并额外包含 `core=2`。

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

### 参数来源

服务端会同时解析以下输入，并统一做字段归一化：

| 来源 | 说明 |
|------|------|
| 路径参数 | 适合快速拼接 URL 调用 |
| Query 参数 | 适合 GET 请求 |
| `application/json` | 适合标准 API 接入 |
| Form 表单 | 适合传统 Web 表单 |

字段名会先去掉符号与空格，再转成小写字母数字，因此 `deviceKey`、`device-key`、`device_key` 会被视为同一个字段。

### 常用字段

| 字段 | 说明 |
|------|------|
| `devicekey` | 单个设备 Key，支持逗号分隔多个值 |
| `devicekeys` | 设备 Key 数组 |
| `devicetoken` | 直接使用推送 Token 发送 |
| `title` / `subtitle` / `body` | 通知标题、副标题、正文 |
| `sound` | 声音名称，不带 `.caf` 时服务端会自动补全 |
| `category` | 仅支持 `myNotificationCategory` 或 `markdown` |
| `url` / `icon` / `copy` / `autocopy` / `level` / `badge` | 自定义扩展字段 |
| `id` | 消息 ID；未传时自动生成 UUID |
| `group` | APNs `thread-id`，也可作为设备分组字段 |
| `location` | 两种模式：传坐标 `"lat,lng"` 显示地图按钮；传合法 URL 触发 Location Push 获取设备位置 |
| `pushgroupname` | 管理员按设备分组批量推送 |

### 兼容别名与默认值

| 规则 | 说明 |
|------|------|
| `data` / `content` / `message` / `text` | 自动映射到 `body` |
| `markdown` / `md` | 自动映射到 `body`，并强制 `category=markdown` |
| `autocopy` | 默认值为 `0` |
| `level` | 默认值为 `active` |
| `category` | 默认值为 `myNotificationCategory` |

### 推送模式

| 模式 | 触发条件 |
|------|------|
| 普通通知 | 存在 `title`、`subtitle`、`body`、`ciphertext`、`image` 中任一内容字段 |
| 定位推送 | `location` 为合法 URL（有 scheme + host） |
| 地图坐标 | `location` 为 `"纬度,经度"` 坐标时，随普通通知一起下发，在消息卡片显示地图按钮 |
| 静默推送 | 没有内容字段，但存在 `id` |
| 查询模式 | 没有内容字段，且没有 `id`，此时返回设备注册信息而不是发推送 |

### 注销语义

更新已有注册记录时，如果 `token` 长度小于 `64` 且 `group` 与原记录一致，服务端会直接删除该设备记录，可将其视为注销或清空注册。

## 其他

1. APP端负责将<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>发送到服务端。 <br>服务端收到一个推送请求后，将发送推送给Apple服务器。然后手机收到推送

2. 服务端代码: <a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a><br>

3. App代码: <a href="https://github.com/sunvc/NoLet">https://github.com/sunvc/NoLet</a>

# 其他资料

当你需要集成 NoLet 到自己的系统或重新实现后端代码时可能需要推送证书

##### Key ID：*BNY5GUGV38*

##### TeamID：*FUWV6U942Q*

##### 下载地址：[AuthKey.p8](https://s3.wzs.app/AuthKey_BNY5GUGV38_FUWV6U942Q.p8)
