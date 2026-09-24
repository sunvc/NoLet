# Deploying the Service

This guide describes how to deploy the Nolet server, **Nolets**, along with the server's APIs and parameters. Nolets supports both **Apple APNs** and **HarmonyOS Push Kit**, and automatically routes pushes according to the OS type of the user's device.

> **Platform tags:** `全平台` = supported on both Apple and HarmonyOS; `apple` = Apple only; `harmony` = HarmonyOS only. Every parameter below is tagged with the platform it takes effect on.

---

## One-Click Install (Recommended)

Linux / macOS (Docker must be installed; on Linux the script installs Docker automatically if it is missing):

```bash
curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh | bash
```

The script will:

1. Check / install Docker (on macOS, install Docker Desktop yourself beforehand)
2. Write `compose.yaml` in the working directory (default `/opt/nolet` on Linux, `~/.nolet` on macOS)
3. Pull `ghcr.io/sunvc/nolets:latest` and start the container `NoLets` via `docker compose`
4. Poll `http://127.0.0.1:8080/health` for a health check

### Common Examples

```bash
# Custom install directory and port, with a signing key and authorized ID list injected
curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh | bash -s -- \
    --dir /opt/nolet \
    --port 8080 \
    --sign-key "your-sign-key" \
    --auths '["uid1","uid2"]'

# Pass parameters through environment variables
NOLET_PORT=9090 NOLET_SIGN_KEY=xxx TZ=Asia/Shanghai \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh)"

# Uninstall (removes only the container, keeps the data directory)
curl -fsSL https://raw.githubusercontent.com/sunvc/nolets/main/install.sh | bash -s -- --uninstall
```

### Install Script Parameters

| Parameter | Environment Variable | Description | Default | Platform |
|------|----------|------|--------|----------|
| `--dir` | `NOLET_DIR` | Working directory (where compose.yaml and data live) | Linux `/opt/nolet` · macOS `~/.nolet` | 全平台 |
| `--port` | `NOLET_PORT` | Host port mapping | `8080` | 全平台 |
| `--image` | `NOLET_IMAGE` | Docker image | `ghcr.io/sunvc/nolets:latest` | 全平台 |
| `--sign-key` | `NOLET_SIGN_KEY` | App signing key |  | 全平台 |
| `--auths` | `NOLET_AUTHS` | Admin ID list, e.g. `'["uid1","uid2"]'` |  | 全平台 |
| `--tz` | `TZ` | Time zone | `Asia/Shanghai` | 全平台 |
| `--name` | `NOLET_CONTAINER` | Container name | `NoLets` | 全平台 |
| `--uninstall` |  | Remove the container |  | 全平台 |

### Common Operations

```bash
docker logs -f NoLets                                          # View logs
docker restart NoLets                                          # Restart
cd /opt/nolet && docker compose pull && docker compose up -d   # Update to the latest image
```

---

## Docker Deployment

Image registries:

- Docker Hub: `sunvc/nolets:latest`
- GitHub Container Registry: `ghcr.io/sunvc/nolets:latest`

```shell
docker run -d --name NoLets -p 8080:8080 \
  -v ./data:/data --restart=always \
  ghcr.io/sunvc/nolets:latest
```

## Docker Compose Deployment

The Nolets repository ships with `deploy/compose.yaml` and an example configuration. You can copy them directly to your server and start:

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

`config.yaml` is optional; create it only when you need custom configuration and point to it with `--config`. Start:

```shell
docker compose up -d
```

## Binary / Manual Deployment

You can download prebuilt binaries from [GitHub Releases](https://github.com/sunvc/NoLetserver/releases) (Windows, macOS, Linux, FreeBSD, multiple architectures), or build them yourself from the [Nolets repository](https://github.com/sunvc/NoLets):

```sh
./NoLets --config /path/to/config.yaml
```

---

## Configuration File

The `config.yaml` in the project is only an example. **You need to create and specify your own configuration file**, passing its path with `--config` / `-c`.

### Configuration Structure

```yaml
system:
  user: ""                         # Basic auth username
  password: ""                     # Basic auth password
  push_password: ""                # Group push password
  addr: "0.0.0.0:8080"             # Server listening address
  url_prefix: "/"                  # Service URL prefix
  data: "./data"                   # Data storage directory
  name: "NoLets"                   # Service name
  dsn: ""                          # MySQL DSN connection string
  cert: ""                         # TLS certificate path
  key: ""                          # TLS private key path
  sign_key: ""                     # App registration signing key
  reduce_memory_usage: false       # Reduce memory usage (increases CPU consumption)
  proxy_header: ""                 # HTTP header field for the remote IP address
  max_batch_push_count: -1         # Max batch push count, -1 means unlimited
  max_apns_client_count: 1         # Max APNs client connections
  max_device_key_arr_length: 10    # Max device key list length
  concurrency: 262144              # Max concurrent connections (256 * 1024)
  read_timeout: 3s                 # Read timeout
  write_timeout: 3s                # Write timeout
  idle_timeout: 10s                # Idle timeout
  admins: []                       # Admin ID list
  debug: false                     # Enable debug mode
  expired: 0                       # Voice expiration time (seconds)
  icp_info: ""                     # ICP filing information
  time_zone: "UTC"                 # Time zone setting
  voice: false                     # Enable voice support
  auths: []                        # Authorized ID list

apple:
  apnsPrivateKey: ""               # APNs private key content or path
  topic: ""                        # APNs Topic
  keyID: ""                        # APNs Key ID
  teamID: ""                       # APNs Team ID
  develop: false                   # Enable the APNs development environment

harmony:
  project_id: ""                   # HarmonyOS AGC project ID (used in the push URL)
  key_id: ""                       # Service account Key ID (JWT kid)
  private_key: ""                  # Service account RSA private key (PEM content; real newlines required)
  sub_account: ""                  # Service account / sub-account (JWT iss)
  client_id: ""                    # App Client ID (used when revoking pushes)
  auth_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/authorize"
  token_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/token"
  auth_provider_cert_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/certs"
  client_cert_uri: "https://oauth-login.cloud.huawei.com/oauth2/v3/x509?client_id="
  develop: false                   # HarmonyOS test push
```

---

## Command Line Arguments and Environment Variables

### System / General Parameters

| Argument | Environment Variable | Description | Default | Platform |
|------|----------|------|--------|----------|
| `--addr` | `NOLET_SERVER_ADDRESS` | Server listening address | `0.0.0.0:8080` | 全平台 |
| `--url-prefix` | `NOLET_SERVER_URL_PREFIX` | Service URL prefix | `/` | 全平台 |
| `--dir` | `NOLET_SERVER_DATA_DIR` | Data storage directory | `./data` | 全平台 |
| `--dsn` | `NOLET_SERVER_DSN` | MySQL DSN, format `user:pass@tcp(host)/dbname` |  | 全平台 |
| `--cert` | `NOLET_SERVER_CERT` | TLS certificate path |  | 全平台 |
| `--key` | `NOLET_SERVER_KEY` | TLS private key path |  | 全平台 |
| `--reduce-memory-usage` | `NOLET_SERVER_REDUCE_MEMORY_USAGE` | Reduce memory usage (increases CPU consumption) | `false` | 全平台 |
| `--user, -u` | `NOLET_SERVER_BASIC_AUTH_USER` | Basic auth username |  | 全平台 |
| `--password, -p` | `NOLET_SERVER_BASIC_AUTH_PASSWORD` | Basic auth password |  | 全平台 |
| `--push-password` | `NOLET_PUSH_PASSWORD` | Group push authentication password |  | 全平台 |
| `--sign-key, --sk` | `NOLET_SIGN_KEY` | App registration signing key |  | 全平台 |
| `--proxy-header` | `NOLET_SERVER_PROXY_HEADER` | Header field carrying the remote IP behind a proxy |  | 全平台 |
| `--max-batch-push-count` | `NOLET_SERVER_MAX_BATCH_PUSH_COUNT` | Max batch push count; `-1` means unlimited | `-1` | 全平台 |
| `--max-apns-client-count, --max` | `NOLET_SERVER_MAX_APNS_CLIENT_COUNT` | Max APNs client connections | `1` | apple |
| `--max-device-key-arr-length` | `NOLET_CONCURRENCY` | Max number of device keys allowed per request | `10` | 全平台 |
| `--concurrency` | `NOLET_SERVER_CONCURRENCY` | Max concurrent connections | `262144` | 全平台 |
| `--read-timeout` | `NOLET_SERVER_READ_TIMEOUT` | Read request timeout | `3s` | 全平台 |
| `--write-timeout` | `NOLET_SERVER_WRITE_TIMEOUT` | Response write timeout | `3s` | 全平台 |
| `--idle-timeout` | `NOLET_SERVER_IDLE_TIMEOUT` | Keep-Alive idle timeout | `10s` | 全平台 |
| `--debug` | `NOLET_DEBUG` | Enable debug mode | `false` | 全平台 |
| `--voice` | `NOLET_VOICE` | Enable voice support | `false` | 全平台 |
| `--auths` | `NOLET_AUTHS` | Authorized device / admin ID list |  | 全平台 |
| `--Expired, --ex` | `NOLET_EXPIRED_TIME` | Voice expiration time (seconds) | `120` | 全平台 |
| `--ICP, --icp` | `NOLET_ICP_INFO` | ICP filing information |  | 全平台 |
| `--proxy-download, --dp` | `NOLET_PROXY_DOWNLOAD` | Enable proxy download | `false` | 全平台 |
| `--export-path, --dc` | `NOLET_EXPORT_PATH` | Database export path |  | 全平台 |
| `--import-path, --dl` | `NOLET_IMPORT_PATH` | Database import path |  | 全平台 |
| `--build-test` |  | Build test mode |  | 全平台 |
| `--config, -c` |  | Configuration file path |  | 全平台 |
| `--help, -h` |  | Show help information |  | 全平台 |

### Apple APNs Parameters

| Argument | Environment Variable | Description | Default | Platform |
|------|----------|------|--------|----------|
| `--apns-private-key` | `NOLET_APPLE_APNS_PRIVATE_KEY` | APNs private key path or content | Built-in default | apple |
| `--topic` | `NOLET_APPLE_TOPIC` | APNs Topic | `me.uuneo.Meoworld` | apple |
| `--key-id` | `NOLET_APPLE_KEY_ID` | APNs Key ID | `BNY5GUGV38` | apple |
| `--team-id` | `NOLET_APPLE_TEAM_ID` | APNs Team ID | `FUWV6U942Q` | apple |
| `--develop, --dev` | `NOLET_APPLE_DEVELOP` | Use the APNs development environment | `false` | apple |

### HarmonyOS Push Kit Parameters

| Argument | Environment Variable | Description | Default | Platform |
|------|----------|------|--------|----------|
| `--hm-project-id` | `NOLET_HM_PROJECT_ID` | HarmonyOS AGC project ID (used in the push URL) |  | harmony |
| `--hm-key-id` | `NOLET_HM_KEY_ID` | HarmonyOS service account Key ID (JWT kid) |  | harmony |
| `--hm-private-key` | `NOLET_HM_PRIVATE_KEY` | HarmonyOS service account RSA private key (PEM content; real newlines required) |  | harmony |
| `--hm-sub-account` | `NOLET_HM_SUB_ACCOUNT` | HarmonyOS service account / sub-account (JWT iss) |  | harmony |
| `--hm-client-id` | `NOLET_HM_CLIENT_ID` | HarmonyOS app Client ID (used when revoking pushes) |  | harmony |
| `--hm-auth-uri` | `NOLET_HM_AUTH_URI` | HarmonyOS OAuth authorization URI | `https://oauth-login.cloud.huawei.com/oauth2/v3/authorize` | harmony |
| `--hm-token-uri` | `NOLET_HM_TOKEN_URI` | HarmonyOS OAuth token URI (JWT aud) | `https://oauth-login.cloud.huawei.com/oauth2/v3/token` | harmony |
| `--hm-auth-provider-cert-uri` | `NOLET_HM_AUTH_PROVIDER_CERT_URI` | HarmonyOS authorization provider cert URI | `https://oauth-login.cloud.huawei.com/oauth2/v3/certs` | harmony |
| `--hm-client-cert-uri` | `NOLET_HM_CLIENT_CERT_URI` | HarmonyOS client cert URI | `https://oauth-login.cloud.huawei.com/oauth2/v3/x509?client_id=` | harmony |
| `--hm-develop` | `NOLET_HM_DEVELOP` | HarmonyOS test push | `false` | harmony |

### Configuration Precedence

- When using `-c` / `--config`: **config file > command line arguments > environment variables**. Keys written in the config file (even with empty-string values) take the highest priority and override the command line and environment variables.
- When not using `-c`: **command line arguments > environment variables > built-in defaults**.

---

## HarmonyOS Push (HarmonyOS Push Kit)

Besides Apple APNs, the server also supports HarmonyOS Push Kit. Pushes are automatically routed by the OS type of the user's device; there is no extra switch — just configure the HarmonyOS credentials.

### Authentication Flow

1. Sign a JWT with the service account's RSA private key using the **PS256** algorithm: `kid` is the Key ID, `iss` is the sub-account, `aud` is the Token URI, and it is valid for 1 hour (the program caches it and refreshes ahead of expiry);
2. Normal pushes call `https://push-api.cloud.huawei.com/v3/{projectID}/messages:send` with the header `Authorization: Bearer <JWT>`;
3. Background silent pushes (with no notification content) call `messages:revoke` to revoke the message, in which case the **Client ID** is used in the URL.

### Obtaining Credentials (AppGallery Connect)

| Config Item | Where to Get It | Platform |
|--------|----------|----------|
| Project ID `project_id` | AGC -> "Project settings" -> "General" -> Project ID | harmony |
| Client ID `client_id` | AGC -> "Project settings" -> "General" -> App information -> Client ID | harmony |
| Key ID `key_id` | AGC -> "Users and permissions" -> "Service accounts" -> create/view key | harmony |
| Private key `private_key` | Contents of the PEM file downloaded when creating the service account key | harmony |
| Sub-account `sub_account` | The corresponding account under AGC -> "Users and permissions" -> "Service accounts" | harmony |

### Notes

- **Private key newlines**: the PEM must contain real newlines. When injecting it through an environment variable, use single quotes and paste the multi-line content directly. A `\n` written inside double quotes is not unescaped by the shell; the program receives a literal backslash followed by n, which causes PEM parsing to fail.
- **Environment variable case**: the test-push switch variable is the all-uppercase `NOLET_HM_DEVELOP`. Environment variables are case-sensitive on Linux.
- **Using together with a config file**: keys written in the harmony section of the config file specified by `-c` (including empty strings) override environment variables of the same name. If you want everything configured purely through environment variables, do not use `-c`.
- **Test push**: after enabling `--hm-develop` or the system-wide `--debug`, push requests are sent as test messages (`TestMessage`). Platform: harmony.

---

## Service Endpoints

### Basic Endpoints

| Endpoint | Description | Platform |
|------|------|----------|
| `GET /ping` | Connectivity check | 全平台 |
| `GET /health` / `GET /healthz` | Health check | 全平台 |
| `GET /info` | Service info and monitoring data | 全平台 |
| `POST /register` | Register / update a device | 全平台 |
| `GET /register/:deviceKey` | Validate or restore a device key | 全平台 |
| `POST /push` | Standard JSON / Form push | 全平台 |
| `POST /ptt/connect` | Create a PTT voice connection | apple |
| `POST /ptt/voice` | Upload or send PTT voice | apple |
| `GET /ptt/voice/:name` | Fetch a PTT voice file | apple |

### Unified Response

The server always returns JSON:

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "trace": "trace-id",
  "timestamp": 1720000000
}
```

Note: many failure cases in Nolets still return HTTP 200. Treat the `code` and `message` in the JSON as the real business status.

---

## Register API

### `POST /register`

Request body fields:

| Field | Description | Platform |
|------|------|----------|
| `key` | Device key; can be empty, in which case the server generates one automatically | 全平台 |
| `token` | Standard push token | 全平台 |
| `talk` | PushToTalk call token | apple |
| `location` | Location push token (Location Push) | apple |
| `group` | Device group; can be empty | 全平台 |

The returned `data` matches the unified response and additionally contains `core=2`.

### `GET /register/:deviceKey`

Used to validate or restore an existing device key:

| Scenario | Behavior |
|------|------|
| Key already exists | Returns success |
| Key does not exist and the current request is from an admin | Creates an empty record and returns success |
| Key does not exist and the request is not from an admin | Returns an error |

### Authentication Rules

Both `/register` and `/register/:deviceKey` go through the signature validation middleware:

| Condition | Description |
|------|------|
| Admin request | Can skip signature validation |
| Non-admin request | `User-Agent` must start with `NoLet` |
| `sign_key` configured | Must additionally provide `Authorization` or `X-Signature` |
| Signature payload | After decryption it must be a timestamp differing from server time by no more than 10 seconds |

---

## Push API

### Supported Entry Points

| Endpoint | Description |
|------|------|
| `POST /push` | Standard JSON / Form push |
| `GET /:deviceKey` | Parameterized push or registration info lookup |
| `POST /:deviceKey` | Parameterized push |
| `GET/POST /:deviceKey/:body` | Path-based body push |
| `GET/POST /:deviceKey/:title/:body` | Path-based title + body push |
| `GET/POST /:deviceKey/:title/:subtitle/:body` | Path-based title + subtitle + body push |

> The `subtitle` in the path only takes effect on Apple devices; HarmonyOS ignores this field. Platform: apple.

### Parameter Sources

The server parses all of the following inputs at once and normalizes fields uniformly:

| Source | Description |
|------|------|
| Path parameters | Good for quickly constructing URLs |
| Query parameters | Good for GET requests |
| `application/json` | Good for standard API integration |
| Form fields | Good for traditional web forms |

Field names are first stripped of symbols and spaces and then converted to lowercase alphanumerics, so `deviceKey`, `device-key`, and `device_key` are treated as the same field.

### Common Fields

| Field | Description | Platform |
|------|------|----------|
| `devicekey` | A single device key; comma-separated multiple values are supported | 全平台 |
| `devicekeys` | Array of device keys | 全平台 |
| `devicetoken` | Send directly using a push token | 全平台 |
| `title` | Notification title | 全平台 |
| `subtitle` | Notification subtitle | apple |
| `body` | Notification body (aliases content / message / data / text are accepted) | 全平台 |
| `markdown` / `md` | Markdown body; forces `category=markdown` | 全平台 |
| `sound` | Sound name. Without an extension the server auto-completes `.caf` for Apple; on HarmonyOS the app reads the same-named `.mp3` from the bundled rawfile directory | 全平台 |
| `category` | Notification category; only `myNotificationCategory` / `markdown` or `alfa`…`zulu` are supported | apple |
| `level` | Interruption level: passive / active / timeSensitive / critical | apple |
| `volume` | Critical alert volume 0…10 | apple |
| `badge` | Badge count; `<=0` clears it | 全平台 |
| `call` | Ringtone control (platform-dependent). Apple: `call=1` loops the ringtone for about 30 seconds, an http(s) URL downloads audio to use as a long ringtone, and any other text is fed to the TTS voice script. HarmonyOS: a numeric value of `10`–`60` sets the ringtone duration in seconds (how long the sound plays) | 全平台 |
| `url` | Link opened on tap | 全平台 |
| `icon` | Sender icon URL (URL form) | 全平台 |
| `image` | Image attachment URL | 全平台 |
| `copy` | Text copied by the dedicated "Copy" action | 全平台 |
| `autocopy` | Auto-copy switch, default `0` | apple |
| `savealbum` | Whether to save the image to the system photo album | apple |
| `id` | Message ID; auto-generated UUID when omitted | 全平台 |
| `group` | APNs `thread-id`; can also serve as a device group field | 全平台 |
| `location` | Coordinates `"lat,lng"` to show a map button, or a callback URL to trigger Location Push | apple |
| `pushgroupname` | Batch push by admins targeting a device group | 全平台 |
| `ciphertext` | Encrypted push ciphertext (base64) | 全平台 |
| `ciphernumber` | Index of the decryption key in the key list, default `0` | 全平台 |
| `script` | Background handler script name | apple |
| `plugin` | Notification plugin script name | apple |

### Compatibility Aliases and Defaults

| Rule | Description | Platform |
|------|------|----------|
| `data` / `content` / `message` / `text` | Automatically mapped to `body` | 全平台 |
| `markdown` / `md` | Automatically mapped to `body` and forces `category=markdown` | 全平台 |
| `autocopy` | Defaults to `0` | apple |
| `level` | Defaults to `active` | apple |
| `category` | Defaults to `myNotificationCategory` | apple |

### Push Modes

| Mode | Trigger Condition | Platform |
|------|----------|----------|
| Standard notification | Any content field among `title`, `subtitle`, `body`, `ciphertext`, `image` is present | 全平台 |
| Location push | `location` is a valid URL (has scheme + host) | apple |
| Map coordinates | `location` is a `"latitude,longitude"` coordinate pair; delivered with a standard notification and shows a map button | apple |
| Silent push | No content fields, but `id` is present | 全平台 |
| Query mode | No content fields and no `id`; returns the device registration info instead of sending a push | 全平台 |

### Unregister Semantics

When updating an existing registration record, if `token` is shorter than `64` characters and `group` matches the original record, the server deletes that device record directly. This can be treated as unregistering or clearing the registration.

---

## Additional Resources

Server code: <a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a>
App code: <a href='https://github.com/sunvc/NoLet'>https://github.com/sunvc/NoLet</a>

You may need the APNs push certificate when integrating Nolet into your own system or re-implementing the backend (required on Apple only; platform: apple):

- Key ID: `BNY5GUGV38`
- Team ID: `FUWV6U942Q`
- Download: [AuthKey.p8](https://s3.wzs.app/AuthKey_BNY5GUGV38_FUWV6U942Q.p8)
