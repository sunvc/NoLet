# Docker-Compose

* Configuration file (Optional, only used for extensive customization)

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

## Command Line Arguments

In addition to the configuration file, the service can be configured via command line arguments or environment variables:

| Argument | Environment Variable | Description | Default |
|------|----------|------|--------|
| `--addr` | `NOLET_SERVER_ADDRESS` | Server listening address | `0.0.0.0:8080` |
| `--url-prefix` | `NOLET_SERVER_URL_PREFIX` | Service URL prefix | `/` |
| `--dir` | `NOLET_SERVER_DATA_DIR` | Data storage directory | `./data` |
| `--dsn` | `NOLET_SERVER_DSN` | MySQL DSN, format: `user:pass@tcp(host)/dbname` | Empty |
| `--cert` | `NOLET_SERVER_CERT` | TLS certificate path | Empty |
| `--key` | `NOLET_SERVER_KEY` | TLS private key path | Empty |
| `--reduce-memory-usage` | `NOLET_SERVER_REDUCE_MEMORY_USAGE` | Reduce memory usage (increases CPU consumption) | `false` |
| `--user, -u` | `NOLET_SERVER_BASIC_AUTH_USER` | Basic Auth username | Empty |
| `--password, -p` | `NOLET_SERVER_BASIC_AUTH_PASSWORD` | Basic Auth password | Empty |
| `--push-password` | `NOLET_PUSH_PASSWORD` | Push authentication password | Empty |
| `--sign-key, --sk` | `NOLET_SIGN_KEY` | App registration signature key | Empty |
| `--proxy-header` | `NOLET_SERVER_PROXY_HEADER` | Source of remote IP address in HTTP header | Empty |
| `--max-batch-push-count` | `NOLET_SERVER_MAX_BATCH_PUSH_COUNT` | Max batch push count, `-1` means unlimited | `-1` |
| `--max-apns-client-count, --max` | `NOLET_SERVER_MAX_APNS_CLIENT_COUNT` | Max APNs client connection count | `1` |
| `--max-device-key-arr-length` | `NOLET_CONCURRENCY` | Max number of device keys allowed in one request | `10` |
| `--concurrency` | `NOLET_SERVER_CONCURRENCY` | Max concurrent connections | `262144` |
| `--read-timeout` | `NOLET_SERVER_READ_TIMEOUT` | Read request timeout | `3s` |
| `--write-timeout` | `NOLET_SERVER_WRITE_TIMEOUT` | Response write timeout | `3s` |
| `--idle-timeout` | `NOLET_SERVER_IDLE_TIMEOUT` | Keep-Alive idle timeout | `10s` |
| `--debug` | `NOLET_DEBUG` | Enable debug mode | `false` |
| `--voice` | `NOLET_VOICE` | Enable voice support | `false` |
| `--auths` | `NOLET_AUTHS` | Authorized device ID list | Empty |
| `--apns-private-key` | `NOLET_APPLE_APNS_PRIVATE_KEY` | APNs private key path | Built-in default |
| `--topic` | `NOLET_APPLE_TOPIC` | APNs Topic | `me.uuneo.Meoworld` |
| `--key-id` | `NOLET_APPLE_KEY_ID` | APNs Key ID | `BNY5GUGV38` |
| `--team-id` | `NOLET_APPLE_TEAM_ID` | APNs Team ID | `FUWV6U942Q` |
| `--develop, --dev` | `NOLET_APPLE_DEVELOP` | Enable APNs development environment | `false` |
| `--Expired, --ex` | `NOLET_EXPIRED_TIME` | Voice expiration time (seconds) | `120` |
| `--ICP, --icp` | `NOLET_ICP_INFO` | ICP filing info | Empty |
| `--proxy-download, --dp` | `NOLET_PROXY_DOWNLOAD` | Enable proxy download | `false` |
| `--export-path, --dc` | `NOLET_EXPORT_PATH` | Export database path | Empty |
| `--import-path, --dl` | `NOLET_IMPORT_PATH` | Import database path | Empty |
| `--help, -h` | - | Show help information | - |
| `--config, -c` | - | Specify configuration file path | - |

Command line arguments take precedence over the configuration file, and environment variables take precedence over command line arguments.

## Docker Deployment

```shell

docker run -d --name NoLets -p 8080:8080 -v ./data:/data --restart=always ghcr.io/sunvc/nolet:latest
```

## Docker-compose Deployment

* The `NoLets` repository includes `deploy/compose.yaml` and an example `config.yaml`, which can be copied to the server directly.
* `config.yaml` is optional and is only needed when you want custom configuration, typically together with `--config`.

* Start

```shell
docker-compose up -d
```

## Manual Deployment

1. Download the executable for your platform or compile it yourself:<br>
<a href="https://github.com/sunvc/NoLets">NoLets</a>

2. Run with a config file

---

```sh
./NoLets --config /path/to/config.yaml
```

## Service Endpoints

### Basic Endpoints

| Endpoint | Description |
|------|------|
| `GET /ping` | Connectivity check |
| `GET /health` / `GET /healthz` | Health check |
| `GET /info` | Service info and monitoring data |
| `POST /ptt/connect` | Create a PTT connection |
| `POST /ptt/voice` | Upload or send PTT voice data |
| `GET /ptt/voice/:name` | Fetch a PTT voice file |

### Unified Response

The server returns JSON in the following shape:

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "trace": "trace-id",
  "timestamp": 1720000000
}
```

Note: many failures in `NoLets` still use HTTP 200. Use the JSON `code` and `message` as the actual business result.

## Register API

### `POST /register`

Request body fields:

| Field | Description |
|------|------|
| `key` | Device key. Optional; the server generates one when empty |
| `token` | Standard push token |
| `talk` | PushToTalk token |
| `location` | Location push token |
| `group` | Device group, optional |

The response `data` uses the same structure and additionally includes `core=2`.

### `GET /register/:deviceKey`

Used to validate or restore an existing device key:

| Scenario | Behavior |
|------|------|
| Key exists | Returns success |
| Key does not exist and the request is from an admin | Creates an empty record and returns success |
| Key does not exist and the request is not from an admin | Returns an error |

### Authentication Rules

Both `/register` and `/register/:deviceKey` go through signature validation middleware:

| Condition | Description |
|------|------|
| Admin request | Can skip signature validation |
| Non-admin request | `User-Agent` must start with `NoLet` |
| `sign_key` configured | Must also provide `Authorization` or `X-Signature` |
| Signature payload | Must decrypt to a timestamp within 10 seconds of server time |

## Push API

### Supported Entry Points

| Endpoint | Description |
|------|------|
| `POST /push` | Standard JSON / Form push |
| `GET /:deviceKey` | Parameterized push or registration lookup |
| `POST /:deviceKey` | Parameterized push |
| `GET/POST /:deviceKey/:body` | Path-based body push |
| `GET/POST /:deviceKey/:title/:body` | Path-based title + body push |
| `GET/POST /:deviceKey/:title/:subtitle/:body` | Path-based title + subtitle + body push |

### Parameter Sources

The server parses and normalizes all of the following inputs:

| Source | Description |
|------|------|
| Path params | Good for quick URL-based calls |
| Query params | Good for GET requests |
| `application/json` | Good for standard API integrations |
| Form fields | Good for traditional web form submissions |

Field names are normalized by removing symbols and spaces, then lowercasing letters, so `deviceKey`, `device-key`, and `device_key` are treated as the same field.

### Common Fields

| Field | Description |
|------|------|
| `devicekey` | A single device key; comma-separated multiple values are supported |
| `devicekeys` | Array of device keys |
| `devicetoken` | Push directly by token |
| `title` / `subtitle` / `body` | Notification title, subtitle, and body |
| `sound` | Sound name. `.caf` is appended automatically when omitted |
| `category` | Only `myNotificationCategory` or `markdown` is valid |
| `url` / `icon` / `copy` / `autocopy` / `level` / `badge` | Custom extension fields |
| `id` | Message ID; auto-generated as a UUID when omitted |
| `group` | APNs `thread-id`, also usable as a device group |
| `location` | Two modes: pass `"lat,lng"` coordinates to show a map button; pass a valid URL to trigger a Location Push that retrieves the device location |
| `pushgroupname` | Admin-only group push by device group |

### Aliases and Defaults

| Rule | Description |
|------|------|
| `data` / `content` / `message` / `text` | Automatically mapped to `body` |
| `markdown` / `md` | Automatically mapped to `body` and forces `category=markdown` |
| `autocopy` | Defaults to `0` |
| `level` | Defaults to `active` |
| `category` | Defaults to `myNotificationCategory` |

### Push Modes

| Mode | Trigger |
|------|------|
| Standard notification | Any of `title`, `subtitle`, `body`, `ciphertext`, or `image` is present |
| Location push | `location` is a valid URL (has scheme + host) |
| Map coordinates | When `location` is `"lat,lng"` coordinates, sent with a standard notification and shows a map button on the message card |
| Silent push | No content fields, but `id` exists |
| Query mode | No content fields and no `id`; returns registration info instead of sending a push |

### Unregister Behavior

When updating an existing registration, if `token` is shorter than `64` and `group` matches the stored record, the server deletes that device record directly. You can treat this as unregistering or clearing the registration.

## Others

1. The App is responsible for sending the <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a> to the server. <br>When the server receives a push request, it will send the push to the Apple server. Then the phone receives the push notification.

2. Server-side code: <a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a><br>

3. App code: <a href="https://github.com/sunvc/NoLet">https://github.com/sunvc/NoLet</a>

# Other Resources

You may need the push certificate when you need to integrate NoLet into your own system or re-implement the backend code.

##### Key ID：*BNY5GUGV38*

##### TeamID：*FUWV6U942Q*

##### Download Link: [AuthKey.p8](https://s3.wzs.app/AuthKey_BNY5GUGV38_FUWV6U942Q.p8)
