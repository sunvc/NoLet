# Send Notification

1. Open the APP and copy the test URL.

<img src="../_media/example.png" width=365 />

2. Modify the content and request this URL.<br>
You can send GET or POST requests. You will receive the notification immediately upon a successful request.<br>
Difference from Bark: Parameter Priority [POST > GET > URL params]. POST parameters will overwrite GET parameters, and so on.

## URL Format

The URL is composed of the push key, title, subtitle, and body. The following combinations are available:

```URL
https://wzs.app/:key/:body
https://wzs.app/:key/:title/:body
https://wzs.app/:key/:title/:subtitle/:body

```

## Request Methods

#### GET Request: Parameters appended to the URL, for example:

```sh
curl https://wzs.app/your_key/push_content?group=group_name&copy=copy_content
```

*When manually appending parameters to the URL, please pay attention to URL encoding. You can refer to [FAQ: URL Encoding](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc)*

##### POST Request: Parameters placed in the request body, for example:

```sh
curl -X POST https://wzs.app/your_key \
     -d'body=push_content&group=group_name&copy=copy_content'
```

##### POST Request supports JSON, for example:

```sh
curl -X "POST" "//https://wzs.app/your_key" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test NoLet Server",
  "title": "Test Title",
  "badge": 1,
  "category": "myNotificationCategory",
  "sound": "minuet.caf",
  "icon": "https://day.app/assets/images/avatar.jpg",
  "group": "test",
  "url": "https://mritd.com"
}'
```

##### JSON Request: key can be placed in the request body, URL path must be `/push`, for example:

```sh
curl -X "POST" "https://wzs.app/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test NoLet Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

## Parameter List

Supported parameter list. Specific effects can be previewed in the APP.
All parameters are compatible with various casing styles: SubTitle / subTitle / subtitle / sub_title / sub-title /

| Parameter | Type | Description |
| ----- | ----------- | ----------- |
| id | String | UUID. Passing the same id overwrites the original message. Passing only the id deletes the message. |
| title | String | Notification Title |
| subtitle | String | Notification Subtitle |
| body | String | Notification Content (Supports content/message/data/text equivalent to body) |
| cipherText | String | Encrypted notification content |
| cipherNumber | Integer | `cipherNumber=0` Key number, 0 is the system default key |
| markdown | String | Markdown syntax (supports abbreviation md) |
| level | String or Integer  | Interruption level.<br>**active**: Default value, the system will immediately light up the screen to display the notification.<br>**timeSensitive**: Time-sensitive notification, can be displayed in Focus mode.<br>**passive**: Only adds the notification to the notification list, will not light up the screen.<br>**critical**: Critical alert, can alert in Focus mode or Silent mode. Can use numbers: `level=1`<br>0: passive<br>1: active<br>2: timeSensitive<br>3...10: critical, in this mode the number will be used for volume (`level=3...10`) |
| volume | Integer/String | Volume in `level=critical&volume=5` mode, range 0...10 |
| call | String | `call=1` Long alert, similar to WeChat call notification |
| badge | String  | `badge=1` Notification badge, can be any number |
| autoCopy | Boolean | `autoCopy=1` or `autoCopy=true` Requires manual long-press or pull-down of the notification |
| copy | String | `copy=copy_content` When copying the notification, specify the content to copy. If this parameter is not passed, the entire notification content will be copied. |
| sound | String | `sound=minuet` You can set different ringtones for notifications. Default ringtone can be set in the app. |
| icon | URL | `icon=https://example.com/icon.png` Set custom icon, automatically cached, supports uploading cloud icons |
| icon | emoji | `icon=🐲` <img src="/_media/example-emoji.png" alt="NoLet App" height="60">  |
| icon | String Array | `icon=Group,ff0000` <img src="/_media/example-word.png" alt="NoLet App" height="60"> |
| image | URL | Pass image URL, automatically downloaded and cached after the phone receives the message |
| savealbum | Boolean | Pass "1" to automatically save the image to the album |
| group | String | Group messages. Notifications will be displayed in the Notification Center grouped by `group`.<br>You can also choose to view different groups in the history message list. |
| ttl | Integer/String | `ttl=days` Notification expiration time, unit: days. Default is set in the app. |
| url | URL  | URL to jump to when clicking the notification. Supports URL Scheme and Universal Link |

## Batch Push

Just pass the device ID list to the `device_keys` parameter. Or a comma-separated string to the `device_key` parameter.

* GET Request:

```sh
https://wzs.app/key1,key2,key3,.../push_content
https://wzs.app/push?deviceKey=key1,key2,key3,...&body=push_content
```

* Or POST Request:

```json
{
     ...// Other parameters
     "deviceKeys": ["key1", "key2", "key3", ...],
}
```

## Group Push

* Server must use sqlite or mysql.
* Server configuration must set user, password.
* Replace the following link with your custom server to generate a QR code, must be added by scanning the code.

```sh
pb://server?text=https://wzs.app&group=newgroup
```

```js
import axios from "axios";

const url = "https://wzs.app/push";
const username = "";
const password = "";
const token = Buffer.from(`${username}:${password}`, "utf8").toString("base64");

axios.post(
  url,
  null,
  {
    headers: {
      Authorization: `Basic ${token}`
    },
    params: {
      PushGroupName: "newgroup",
      body: "Test NoLet Server",
      // ...
    }
  }
)
.then(res => {
  console.log(res.data);
})
.catch(err => {
  console.error(err.response?.data || err.message);
});
```

## MCP Support

```json
{
  "mcpServers": {
    "nolet": {
      "url": "https://wzs.app/mcp/your_device_key"
    }
  }
}
```

## Shortcuts

NoLet supports sending notifications directly using Shortcuts.
Pass Server and KEY, or Device ID. If passing Device ID, it does not go through the server, but pushes directly to Apple servers.
