
*[BARK](https://github.com/Finb/Bark)のオープンソースプロジェクトに感謝します*
### APNSインターフェースを直接呼び出す
デバイスのDeviceToken（APPで確認可能）があれば、Apple APNSインターフェースを直接呼び出してデバイスにプッシュ通知を送信できます。APPにサーバーを追加する必要もありません。<br>
以下はコマンドラインでのプッシュ通知送信例です：

```shell
# 環境変数を設定
# キーをダウンロード https://github.com/sunvc/NoLets/tree/main/pushback.p8
# キーファイルのパスを以下に入力
TOKEN_KEY_FILE_NAME= 
# アプリの設定からDeviceTokenをここにコピー
DEVICE_TOKEN=

# 以下は変更しないでください
TEAM_ID=FUWV6U942Q
AUTH_KEY_ID=BNY5GUGV38
TOPIC=me.sunvc.Meoworld
APNS_HOST_NAME=api.push.apple.com

# TOKENを生成
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# 可能であれば、このトークンをキャッシュするようにスクリプトを改良することをお勧めします。トークンは30分以内は同じものを再利用し、30分ごとに再生成します
# Appleのドキュメントによると、トークン生成の最小間隔は20分、トークンの最大有効期間は60分です
# 間隔が短すぎると生成に失敗し、トークンが1時間を超えて再生成されないとプッシュできなくなります
# しかし、私の無責任な簡単なテストでは、短時間で正常に生成できました
# これは単なる注意点で、頻繁なトークン生成によりプッシュが失敗する可能性があります
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

# プッシュを送信
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}

```

### プッシュパラメータの形式
参考: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification<br>
必ず "mutable-content" : 1 を含めてください。そうしないとプッシュ拡張が実行されず、プッシュが保存されません。<br>

例：
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