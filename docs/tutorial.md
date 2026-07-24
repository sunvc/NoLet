# 发送推送

1. 打开APP，复制测试URL

<img src="../_media/example.png" width=365 />

2. 修改内容，请求这个URL。<br>
可以发 GET 或者 POST 请求 ，请求成功会立即收到推送 <br>
与bark差异：参数权限 【POST > GET > URL params 】 post参数会覆盖get参数以此类推

## URL格式

URL由推送key, title, subtitle, body 组成。有下面组合方式

```URL
https://wzs.app/:key/:body 
https://wzs.app/:key/:title/:body 
https://wzs.app/:key/:title/:subtitle/:body

```

## 请求方式

#### GET 请求参数拼接在 URL 后面，例如

```sh
curl https://wzs.app/your_key/推送内容?group=分组&copy=复制
```

*手动拼接参数到URL上时，请注意URL编码问题，可以参考阅读[常见问题：URL编码](/faq?id=%e6%8e%a8%e9%80%81%e7%89%b9%e6%ae%8a%e5%ad%97%e7%ac%a6%e5%af%bc%e8%87%b4%e6%8e%a8%e9%80%81%e5%a4%b1%e8%b4%a5%ef%bc%8c%e6%af%94%e5%a6%82-%e6%8e%a8%e9%80%81%e5%86%85%e5%ae%b9%e5%8c%85%e5%90%ab%e9%93%be%e6%8e%a5%ef%bc%8c%e6%88%96%e6%8e%a8%e9%80%81%e5%bc%82%e5%b8%b8-%e6%af%94%e5%a6%82-%e5%8f%98%e6%88%90%e7%a9%ba%e6%a0%bc)*

##### POST 请求参数放在请求体中，例如

```sh
curl -X POST https://wzs.app/your_key \
     -d'body=推送内容&group=分组&copy=复制'
```

##### POST 请求支持JSON，例如

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

##### JSON 请求 key 可以放进请求体中,URL 路径须为 /push，例如

```sh
curl -X "POST" "https://wzs.app/push" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "body": "Test NoLet Server",
  "title": "Test Title",
  "device_key": "your_key"
}'
```

## 所有参数列表

支持的参数列表，具体效果可在APP内预览。
所有参数兼容各种写法：SubTitle / subTitle / subtitle / sub_title / sub-title /

| 参数 | 参数类型 | 使用说明 |
| ----- | ----------- | ----------- |
| id | 字符串 | UUID 传入相同id覆盖原有消息，只传id删除消息 |
| title | 字符串 | 推送标题 |
| subtitle | 字符串 | 推送副标题 |
| body | 字符串 | 推送内容( 支持 content/message/data/text 等同body) |
| cipherText | 字符串 | 加密推送内容 |
| cipherNumber | 整数 | `cipherNumber=0` 密钥编号, 0为系统默认密钥 |
| markdown | 字符串 | Markdown语法(支持简写 md) |
| level | 字符串或整数  | 推送中断级别。<br>**active**：默认值，系统会立即亮屏显示通知<br>**timeSensitive**：时效性通知，可在专注状态下显示通知。<br>**passive**：仅将通知添加到通知列表，不会亮屏提醒。<br>**critical**：重要提醒，可在专注模式或者静音模式下提醒。参数可以使用数字替代：`level=1`<br>0：passive<br>1：active<br>2：timeSensitive<br>3...10：critical，此模式数字将用于音量（`level=3...10`） |
| volume | 整数/字符串 | `level=critical&volume=5` 模式下音量，取值范围 0...10 |
| call | 字符串 | `call=1` 长提醒，类似微信电话通知 |
| badge | 字符串  | `badge=1` 推送角标，可以是任意数字 |
| autoCopy | 布尔值 | `autoCopy=1` or `autoCopy=true`  需手动长按推送或下拉推送 |
| copy | 字符串 | `copy=复制内容` 复制推送时，指定复制的内容，不传此参数将复制整个推送内容。 |
| sound | 字符串 | `sound=minuet` 可以为推送设置不同的铃声，应用内可设置默认铃声 |
| icon | URL | `icon=https://example.com/icon.png` 设置自定义图标，图标自动缓存，支持上传云图标 |
| icon | emoji | `icon=🐲` <img src="/_media/example-emoji.png" alt="NoLet App" height="60">  |
| icon | 字符串数组 | `icon=组,ff0000` <img src="/_media/example-word.png" alt="NoLet App" height="60"> |
| image | URL | 传入图片地址，手机收到消息后自动下载缓存 |
| savealbum | 布尔值 | 传"1"自动保存图片到相册 |
| group | 字符串 | 对消息进行分组，推送将按 `group` 分组显示在通知中心中。<br>也可在历史消息列表中选择查看不同的群组。 |
| ttl | 整数/字符串 | `ttl=天数` 推送过期时间，单位天，默认 app 内设置。 |
| url | URL  | 点击推送时，跳转的 URL，支持 URL Scheme 和 Universal Link |
| location | 字符串 | 两种模式：① 传 `"纬度,经度"` 坐标，直接在消息卡片显示地图按钮；② 传回调 URL，触发 Location Push 获取设备位置后 POST 回传（详见消息模板文档） |

## 批量推送

只需传递 `device_keys` 参数的设备ID列表。或者 `device_key`参数的逗号分隔的字符串

* GET请求:

```sh
https://wzs.app/key1,key2,key3,.../推送内容
https://wzs.app/push?deviceKey=key1,key2,key3,...&body=推送内容
```

* 或者POST请求:

```json
{
     ...// 其他参数
     “deviceKeys”: [“key1”, “key2”, “key3”, ...],
}
```

## 分组推送

* 服务器必须使用sqlite或者mysql
* 服务器配置必须设置user,password
* 用自定义服务器替换以下链接生成二维码, 必须扫码添加

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

## MCP 支持

```json
{
  "mcpServers": {
    "nolet": {
      "url": "https://wzs.app/mcp/your_device_key"
    }
  }
}
```

## 快捷指令

Nolet 支持使用快捷指令直接发送推送
传服务器和KEY 或者 设备ID, 传设备ID 不经过服务器,直接推送到苹果服务器.
