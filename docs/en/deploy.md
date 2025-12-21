# Docker-Compose

* Configuration file (Optional, only used for extensive customization)

```yaml
system:
  user: ""
  password: ""
  addr: "0.0.0.0:8080"
  url_prefix: ""
  data: "./data"
  name: "NoLet"
  dsn: ""
  cert: ""
  key: ""
  reduce_memory_usage: false
  proxy_header: ""
  max_batch_push_count: -1
  max_apns_client_count: 1
  concurrency: 262144   # 256 * 1024
  read_timeout: 3s
  write_timeout: 3s
  idle_timeout: 10s
  debug: true
  version: ""
  build_date: ""
  commitID: ""
  expired: 0
  icp_info: ""
  time_zone: "UTC"
  voice: true
  auth_ids: []

apple:
  apnsPrivateKey: |-
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgvjopbchDpzJNojnc
    o7ErdZQFZM7Qxho6m61gqZuGVRigCgYIKoZIzj0DAQehRANCAAQ8ReU0fBNg+sA+
    ZdDf3w+8FRQxFBKSD/Opt7n3tmtnmnl9Vrtw/nUXX4ldasxA2gErXR4YbEL9Z+uJ
    REJP/5bp
    -----END PRIVATE KEY-----
  topic: "me.sunvc.Meoworld"
  keyID: "BNY5GUGV38"
  teamID: "FUWV6U942Q"
  develop: true


```

### Command Line Arguments

In addition to the configuration file, the service can be configured via command line arguments or environment variables:

| Argument | Environment Variable | Description | Default |
|------|----------|------|--------|
| `--addr` | `NoLet_SERVER_ADDRESS` | Server listening address | `0.0.0.0:8080` |
| `--url-prefix` | `NoLet_SERVER_URL_PREFIX` | Service URL prefix | `/` |
| `--dir` | `NoLet_SERVER_DATA_DIR` | Data storage directory | `./data` |
| `--dsn` | `NoLet_SERVER_DSN` | MySQL DSN, format: `user:pass@tcp(host)/dbname` | Empty |
| `--cert` | `NoLet_SERVER_CERT` | TLS certificate path | Empty |
| `--key` | `NoLet_SERVER_KEY` | TLS private key path | Empty |
| `--reduce-memory-usage` | `NoLet_SERVER_REDUCE_MEMORY_USAGE` | Reduce memory usage (increases CPU consumption) | `false` |
| `--user, -u` | `NoLet_SERVER_BASIC_AUTH_USER` | Basic Auth username | Empty |
| `--password, -p` | `NoLet_SERVER_BASIC_AUTH_PASSWORD` | Basic Auth password | Empty |
| `--proxy-header` | `NoLet_SERVER_PROXY_HEADER` | Source of remote IP address in HTTP header | Empty |
| `--max-batch-push-count` | `NoLet_SERVER_MAX_BATCH_PUSH_COUNT` | Max batch push count, `-1` means unlimited | `-1` |
| `--max-apns-client-count` | `NoLet_SERVER_MAX_APNS_CLIENT_COUNT` | Max APNs client connection count | `1` |
| `--admins` | `NoLet_SERVER_ADMINS` | Administrator ID list | Empty |
| `--debug` | `NoLet_DEBUG` | Enable debug mode | `false` |
| `--apns-private-key` | `NoLet_APPLE_APNS_PRIVATE_KEY` | APNs private key path | Empty |
| `--topic` | `NoLet_APPLE_TOPIC` | APNs Topic | Empty |
| `--key-id` | `NoLet_APPLE_KEY_ID` | APNs Key ID | Empty |
| `--team-id` | `NoLet_APPLE_TEAM_ID` | APNs Team ID | Empty |
| `--develop, --dev` | `NoLet_APPLE_DEVELOP` | Enable APNs development environment | `false` |
| `--Expired, --ex` | `NoLet_EXPIRED_TIME` | Voice expiration time (seconds) | `120` |
| `--help, -h` | - | Show help information | - |
| `--config, -c` | - | Specify configuration file path | - |

Command line arguments take precedence over the configuration file, and environment variables take precedence over command line arguments.

## Docker Deployment

```shell

docker run -d --name NoLets -p 8080:8080 -v ./data:/data  --restart=always  sanvc/NoLet:latest
```

## Docker-compose Deployment

* Copy the `/deploy` folder from the project to the server, then run the following command.
* Optional `config.yaml` configuration file. You can modify the configuration items in the file according to your needs.

* Start

```shell
docker-compose up -d
```

## Manual Deployment

1. Download the executable for your platform or compile it yourself:<br>
<a href="https://github.com/sunvc/NoLets">NoLets</a>

2. Run

---

```sh
./main
```

## Others

1. The App is responsible for sending the <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a> to the server. <br>When the server receives a push request, it will send the push to the Apple server. Then the phone receives the push notification.

2. Server-side code: <a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a><br>

3. App code: <a href="https://github.com/sunvc/NoLet">https://github.com/sunvc/NoLet</a>

# Other Resources

You may need the push certificate when you need to integrate NoLet into your own system or re-implement the backend code.

##### Key ID：*BNY5GUGV38*

##### TeamID：*FUWV6U942Q*

##### Download Link: [AuthKey.p8](https://s3.wzs.app/AuthKey_BNY5GUGV38_FUWV6U942Q.p8)
