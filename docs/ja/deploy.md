*[BARK](https://github.com/Finb/Bark)のオープンソースプロジェクトに感謝します*

## Docker-Compose 
* 設定

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

### コマンドラインパラメータ

設定ファイルの他に、コマンドラインパラメータや環境変数を使用してサービスを設定することもできます：


| パラメータ | 環境変数 | 説明 | デフォルト値 |
|------|----------|------|--------|
| `--addr` | `NoLet_SERVER_ADDRESS` | サーバーリスニングアドレス | `0.0.0.0:8080` |
| `--url-prefix` | `NoLet_SERVER_URL_PREFIX` | サービスURLプレフィックス | `/` |
| `--dir` | `NoLet_SERVER_DATA_DIR` | データストレージディレクトリ | `./data` |
| `--dsn` | `NoLet_SERVER_DSN` | MySQL DSN、フォーマット：`user:pass@tcp(host)/dbname` | 空 |
| `--cert` | `NoLet_SERVER_CERT` | TLS 証明書パス | 空 |
| `--key` | `NoLet_SERVER_KEY` | TLS 証明書の秘密鍵パス | 空 |
| `--reduce-memory-usage` | `NoLet_SERVER_REDUCE_MEMORY_USAGE` | メモリ使用量を削減（CPU消費量が増加） | `false` |
| `--user, -u` | `NoLet_SERVER_BASIC_AUTH_USER` | 基本認証ユーザー名 | 空 |
| `--password, -p` | `NoLet_SERVER_BASIC_AUTH_PASSWORD` | 基本認証パスワード | 空 |
| `--proxy-header` | `NoLet_SERVER_PROXY_HEADER` | HTTPヘッダーのリモートIPアドレスソース | 空 |
| `--max-batch-push-count` | `NoLet_SERVER_MAX_BATCH_PUSH_COUNT` | バッチプッシュの最大数、`-1`は無制限を意味する | `-1` |
| `--max-apns-client-count` | `NoLet_SERVER_MAX_APNS_CLIENT_COUNT` | 最大APNsクライアント接続数 | `1` |
| `--admins` | `NoLet_SERVER_ADMINS` | 管理者IDリスト | 空 |
| `--debug` | `NoLet_DEBUG` | デバッグモードを有効にする | `false` |
| `--apns-private-key` | `NoLet_APPLE_APNS_PRIVATE_KEY` | APNs 秘密鍵パス | 空 |
| `--topic` | `NoLet_APPLE_TOPIC` | APNs Topic | 空 |
| `--key-id` | `NoLet_APPLE_KEY_ID` | APNs Key ID | 空 |
| `--team-id` | `NoLet_APPLE_TEAM_ID` | APNs Team ID | 空 |
| `--develop, --dev` | `NoLet_APPLE_DEVELOP` | APNs開発環境を有効にする | `false` |
| `--Expired, --ex` | `NoLet_EXPIRED_TIME` | 音声の有効期限（秒） | `120` |
| `--help, -h` | - | ヘルプ情報を表示 | - |
| `--config, -c` | - | 設定ファイルのパスを指定 | - |

コマンドラインパラメータは設定ファイルより優先され、環境変数はコマンドラインパラメータより優先されます。

## Dockerデプロイ

```shell

docker run -d --name NoLets -p 8080:8080 -v ./data:/data  --restart=always  sanvc/NoLet:latest
```

## Docker-composeデプロイ
* プロジェクト内の/deployフォルダをサーバーにコピーし、以下のコマンドを実行するだけです。
* オプションで `config.yaml` 設定ファイルを使用できます。ファイル内の設定項目は、必要に応じて変更できます。

* 起動
```shell
docker-compose up -d
```

## 手動デプロイ

1. プラットフォームに応じて実行ファイルをダウンロード:<br> <a href='https://github.com/sunvc/NoLets/releases'>https://github.com/sunvc/NoLets/releases</a><br>
または自分でコンパイル<br>
<a href="https://github.com/sunvc/NoLets">https://github.com/sunvc/NoLets</a>

2. 実行
---
```
./main
```

## その他

1. APPは<a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>をサーバーに送信する役割を担います。<br>サーバーはプッシュリクエストを受信すると、Appleサーバーにプッシュを送信します。その後、スマートフォンがプッシュを受信します。

2. サーバーコード: <a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a><br>

3. Appコード: <a href="https://github.com/sunvc/NoLet">https://github.com/sunvc/NoLet</a>

