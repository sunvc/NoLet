
*[BARK](https://github.com/Finb/Bark)의 오픈 소스 프로젝트에 감사드립니다*
### APNS 인터페이스 직접 호출
기기의 DeviceToken(앱에서 확인 가능)이 있으면 애플 APNS 인터페이스를 직접 호출하여 기기로 푸시를 보낼 수 있으며, 앱에 서버를 추가할 필요가 없습니다.<br>
다음은 명령줄에서 푸시를 보내는 예시입니다:

```shell
# 환경 변수 설정
# 키 다운로드 https://github.com/sunvc/NoLets/tree/main/pushback.p8
# 키 파일 경로를 아래에 입력
TOKEN_KEY_FILE_NAME= 
# 앱 설정에서 DeviceToken을 복사하여 여기에 붙여넣기
DEVICE_TOKEN=

# 아래는 수정하지 마세요
TEAM_ID=FUWV6U942Q
AUTH_KEY_ID=BNY5GUGV38
TOPIC=me.sunvc.Meoworld
APNS_HOST_NAME=api.push.apple.com

# TOKEN 생성
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# 가능하다면 이 토큰을 캐시하도록 스크립트를 개선하는 것이 좋습니다. 토큰은 30분 내에 동일한 것을 재사용하고, 30분마다 새로 생성합니다.
# 애플 문서에 따르면 토큰 생성 간격은 최소 20분이며, 토큰 유효 기간은 최대 60분입니다.
# 간격이 너무 짧으면 생성에 실패하고, 토큰이 1시간을 초과하면 푸시를 보낼 수 없습니다.
# 그러나 제 간단한 테스트에 따르면 짧은 시간 내에도 정상적으로 생성될 수 있습니다.
# 여기서는 단지 알림만 드리지만, 토큰을 너무 자주 생성하면 푸시 실패의 원인이 될 수 있습니다
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

#푸시 전송
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}

```

### 푸시 매개변수 형식
참조: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification<br>
반드시 "mutable-content": 1을 포함해야 합니다. 그렇지 않으면 푸시 확장이 실행되지 않고 푸시가 저장되지 않습니다.<br>

예시:
```js
{
    "aps": {
        "mutable-content": 1,
        "alert": {
            "title" : "title",
            "body": "body"
        },
        "category": "myNotificationCategory",
        "sound": "minuet.caf"
    },
    "icon": "https://day.app/assets/images/avatar.jpg"
}
```