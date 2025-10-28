*[BARK](https://github.com/Finb/Bark)의 오픈 소스 프로젝트에 감사드립니다*

## Docker-Compose 
* 구성

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

### 명령줄 매개변수

구성 파일 외에도 명령줄 매개변수나 환경 변수를 통해 서비스를 구성할 수 있습니다:


| 매개변수 | 환경 변수 | 설명 | 기본값 |
|------|----------|------|--------|
| `--addr` | `NoLet_SERVER_ADDRESS` | 서버 리스닝 주소 | `0.0.0.0:8080` |
| `--url-prefix` | `NoLet_SERVER_URL_PREFIX` | 서비스 URL 접두사 | `/` |
| `--dir` | `NoLet_SERVER_DATA_DIR` | 데이터 저장 디렉토리 | `./data` |
| `--dsn` | `NoLet_SERVER_DSN` | MySQL DSN, 형식: `user:pass@tcp(host)/dbname` | 없음 |
| `--cert` | `NoLet_SERVER_CERT` | TLS 인증서 경로 | 없음 |
| `--key` | `NoLet_SERVER_KEY` | TLS 인증서 개인 키 경로 | 없음 |
| `--reduce-memory-usage` | `NoLet_SERVER_REDUCE_MEMORY_USAGE` | 메모리 사용량 감소(CPU 소비 증가) | `false` |
| `--user, -u` | `NoLet_SERVER_BASIC_AUTH_USER` | 기본 인증 사용자 이름 | 없음 |
| `--password, -p` | `NoLet_SERVER_BASIC_AUTH_PASSWORD` | 기본 인증 비밀번호 | 없음 |
| `--proxy-header` | `NoLet_SERVER_PROXY_HEADER` | HTTP 헤더의 원격 IP 주소 소스 | 없음 |
| `--max-batch-push-count` | `NoLet_SERVER_MAX_BATCH_PUSH_COUNT` | 일괄 푸시 최대 수량, `-1`은 무제한을 의미 | `-1` |
| `--max-apns-client-count` | `NoLet_SERVER_MAX_APNS_CLIENT_COUNT` | 최대 APNs 클라이언트 연결 수 | `1` |
| `--admins` | `NoLet_SERVER_ADMINS` | 관리자 ID 목록 | 없음 |
| `--debug` | `NoLet_DEBUG` | 디버그 모드 활성화 | `false` |
| `--apns-private-key` | `NoLet_APPLE_APNS_PRIVATE_KEY` | APNs 개인 키 경로 | 없음 |
| `--topic` | `NoLet_APPLE_TOPIC` | APNs Topic | 없음 |
| `--key-id` | `NoLet_APPLE_KEY_ID` | APNs Key ID | 없음 |
| `--team-id` | `NoLet_APPLE_TEAM_ID` | APNs Team ID | 없음 |
| `--develop, --dev` | `NoLet_APPLE_DEVELOP` | APNs 개발 환경 활성화 | `false` |
| `--Expired, --ex` | `NoLet_EXPIRED_TIME` | 음성 만료 시간(초) | `120` |
| `--help, -h` | - | 도움말 표시 | - |
| `--config, -c` | - | 구성 파일 경로 지정 | - |

명령줄 매개변수의 우선순위는 구성 파일보다 높고, 환경 변수의 우선순위는 명령줄 매개변수보다 높습니다.

## Docker 배포

```shell

docker run -d --name NoLets -p 8080:8080 -v ./data:/data  --restart=always  sanvc/NoLet:latest
```

## Docker-compose 배포
* 프로젝트의 /deploy 폴더를 서버에 복사한 다음 아래 명령을 실행하면 됩니다.
* 선택적으로 `config.yaml` 구성 파일을 사용할 수 있으며, 파일의 구성 항목은 필요에 따라 수정할 수 있습니다.

* 시작
```shell
docker-compose up -d
```

## 수동 배포

1. 플랫폼에 따라 실행 파일 다운로드:<br> <a href='https://github.com/sunvc/NoLets/releases'>https://github.com/sunvc/NoLets/releases</a><br>
또는 직접 컴파일<br>
<a href="https://github.com/sunvc/NoLets">https://github.com/sunvc/NoLets</a>

2. 실행
---
```
./main
```

## 기타

1. APP 측에서 <a href="https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application">DeviceToken</a>을 서버 측으로 전송합니다. <br>서버 측에서 푸시 요청을 받으면 Apple 서버로 푸시를 전송합니다. 그런 다음 휴대폰에서 푸시를 받습니다.

2. 서버 측 코드: <a href='https://github.com/sunvc/NoLets'>https://github.com/sunvc/NoLets</a><br>

3. 앱 코드: <a href="https://github.com/sunvc/NoLet">https://github.com/sunvc/NoLet</a>

