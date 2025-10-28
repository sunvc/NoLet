*Thanks to the [BARK](https://github.com/Finb/Bark) open source project*

## Sending Push Notifications 
1. Open the app and copy the test URL

<img src="../_media/example.png" width=365 />

2. Modify the content and request this URL.<br>
You can send GET or POST requests. Upon successful request, you will immediately receive a push notification <br>
Difference from bark: Parameter priority 【POST > GET > URL params】 POST parameters will override GET parameters and so on

## URL Format
The URL consists of push key, title parameter, and body parameter. There are two combination methods below

```
https://wzs.app/:key/:body 
https://wzs.app/:key/:title/:body 
https://wzs.app/:key/:title/:subtitle/:body

```

## Request Methods
##### GET request parameters are appended to the URL, for example:
```sh
curl https://wzs.app/your_key/push_content?group=group&copy=copy
```
*When manually appending parameters to the URL, please pay attention to URL encoding issues. You can refer to [FAQ: URL Encoding](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc)*

##### POST request parameters are placed in the request body, for example:
```sh
curl -X POST https://wzs.app/your_key \
     -d'body=push_content&group=group&copy=copy'
```
##### POST requests support JSON, for example:
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

##### JSON request key can be placed in the request body, URL path must be /push, for example
```sh
curl -X "POST" "https://wzs.app/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test NoLet Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

## All Parameters List
Supported parameter list, specific effects can be previewed in the app.
All parameters are compatible with various writing styles: SubTitle / subTitle / subtitle / sub_title / sub-title /

| Parameter | Parameter Type | Usage Description |
| ----- | ----------- | ----------- |
| id | String | UUID Passing the same id will overwrite the original message, passing only id will delete the message |
| title | String | Push title |
| subtitle | String | Push subtitle |
| body | String | Push content (supports content/message/data/text equivalent to body) |
| cipherText | String | Encrypted push content |
| cipherNumber | Integer | `cipherNumber=0` Encryption key number, 0 is the system default key |
| markdown | String | Markdown syntax (supports abbreviation md) |
| level | String or Integer  | Push interruption level.<br>**active**: Default value, system will immediately light up the screen to display notification<br>**timeSensitive**: Time-sensitive notification, can display notifications in focus mode<br>**passive**: Only add notification to notification list, will not light up the screen<br>**critical**: Important reminder, can remind in focus mode or silent mode. Parameters can use numbers instead: `level=1`<br>0: passive<br>1: active<br>2: timeSensitive<br>3...10: critical, in this mode numbers will be used for volume (`level=3...10`) |
| volume | Integer/String | `level=critical&volume=5` Volume in mode, range 0...10 |
| call | String | `call=1` Long reminder, similar to WeChat phone notification |
| badge | String  | `badge=1` Push badge, can be any number |
| autoCopy | Boolean | `autoCopy=1` or `autoCopy=true` Need to manually long press or pull down the push |
| copy | String | `copy=copy_content` When copying push, specify the content to copy, if this parameter is not passed, the entire push content will be copied |
| sound | String | `sound=minuet` Can set different ringtones for push, default ringtone can be set in the app |
| icon | URL | `icon=https://example.com/icon.png` Set custom icon, icon is automatically cached, supports uploading cloud icons |
| icon | emoji | `icon=🐲` <img src="/_media/example-emoji.png" alt="NoLet App" height="60">  |
| icon | String Array | `icon=group,ff0000` <img src="/_media/example-word.png" alt="NoLet App" height="60"> |
| image | URL | Pass image address, phone will automatically download and cache after receiving message |
| savealbum | Boolean | Pass "1" to automatically save image to album |
| group | String | Group messages, push will be displayed in groups by `group` in the notification center.<br>You can also select to view different groups in the history message list. |
| ttl | Integer/String | `ttl=days` Push expiration time, unit is days, default app internal setting |
| url | URL  | URL to jump to when clicking push, supports URL Scheme and Universal Link |
