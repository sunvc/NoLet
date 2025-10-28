
*Thanks to the open source project [BARK](https://github.com/Finb/Bark)*
### Directly Call APNS Interface
If you have the device's DeviceToken (viewable in the APP), you can call Apple's APNS interface to send push notifications directly to the device, without adding a server in the APP.<br>
Here is a command line example for sending push notifications:

```shell
# Set environment variables
# Download key from https://github.com/sunvc/NoLets/tree/main/pushback.p8
# Fill in the key file path below
TOKEN_KEY_FILE_NAME= 
# Copy DeviceToken from app settings here
DEVICE_TOKEN=

# Do not modify the following
TEAM_ID=FUWV6U942Q
AUTH_KEY_ID=BNY5GUGV38
TOPIC=me.sunvc.Meoworld
APNS_HOST_NAME=api.push.apple.com

# Generate TOKEN
JWT_ISSUE_TIME=$(date +%s)
JWT_HEADER=$(printf '{ "alg": "ES256", "kid": "%s" }' "${AUTH_KEY_ID}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_CLAIMS=$(printf '{ "iss": "%s", "iat": %d }' "${TEAM_ID}" "${JWT_ISSUE_TIME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
JWT_HEADER_CLAIMS="${JWT_HEADER}.${JWT_CLAIMS}"
JWT_SIGNED_HEADER_CLAIMS=$(printf "${JWT_HEADER_CLAIMS}" | openssl dgst -binary -sha256 -sign "${TOKEN_KEY_FILE_NAME}" | openssl base64 -e -A | tr -- '+/' '-_' | tr -d =)
# If possible, it's best to improve the script to cache this Token. Reuse the same Token within 30 minutes, regenerate every 30 minutes
# Apple documentation states that TOKEN generation interval should be at least 20 minutes, TOKEN validity is maximum 60 minutes
# Generating too frequently will fail, and not regenerating after 1 hour will prevent push notifications
# Based on my simple, non-rigorous testing, it can be generated normally in a short time
# This is just a reminder that frequent TOKEN generation may cause push notification failures
AUTHENTICATION_TOKEN="${JWT_HEADER}.${JWT_CLAIMS}.${JWT_SIGNED_HEADER_CLAIMS}"

# Send push notification
curl -v --header "apns-topic: $TOPIC" --header "apns-push-type: alert" --header "authorization: bearer $AUTHENTICATION_TOKEN" --data '{"aps":{"alert":"test"}}' --http2 https://${APNS_HOST_NAME}/3/device/${DEVICE_TOKEN}

```

### Push Notification Parameter Format
Reference: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification<br>
You must include "mutable-content": 1, otherwise the push extension will not execute and the push notification will not be saved.<br>

Example:
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