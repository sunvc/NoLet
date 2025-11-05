  
中文 ｜ **[English](README.EN.md)** | **[日本語](README.JA.md)** | **[한국어](README.KO.md)**

<p align="center">

<img src="/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# NoLet 无字书
### 是一款为iOS平台设计可让您将自定义通知推送到您的苹果设备的应用程序。

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-26.0-blue?logo=Xcode&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-5.10-red?logo=Swift&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-16.0+-green?logo=apple&logoColor=white" alt="NoLet App"></td>
  </tr>
</table>

| TestFlight | App Store | 文档 | 反馈群 |
|-------|--------|-------|--------|
|[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="NoLet App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="NoLet App" height="40">](https://apps.apple.com/app/id6615073345)| [使用文档](https://wiki.wzs.app) | [NoLet](https://t.me/PushToMe) |


## 应用介绍

NoLet 无字书 是一款强大的iOS推送工具，让你能够从任何设备向iPhone/iPad发送自定义通知。无论是服务器监控、脚本自动化还是日常提醒，NoLet 无字书都能满足你的需求。

> [!IMPORTANT]
>
>  - 简单易用的API，支持多种请求方式
>  - Markdown渲染支持，让推送内容更丰富
>  - 自定义铃声、远程图标、文字图标，Emoji图标和图片
>  - 多种通知级别，包括时效性和关键通知
>  - 浏览器扩展支持，一键分享网页内容
>  - 低功耗设计，对电池影响极小
>  - 项目开源，可自建服务器
>  - 消息支持端到端加密



|Markdown|Avatar And Image|
|-------|--------|
|<img src="/_media/markdown.gif" width="350">|<img src="/_media/avatarAndImage.gif" width="350">|
  

### 自建推送服务器

* NoLet 无字书支持自建服务器，保证数据隐私和安全
* 服务器代码开源：[NoLetServer](https://github.com/sunvc/NoLets)
* 自建服务器支持多平台部署（Windows、macOS、Linux等）
* 支持Docker容器化部署，便于维护和升级

## 浏览器扩展

| Safari | Chrome | Firefox | Edge |
|-------|--------|-------|--------|
| [MacOS](https://apps.apple.com/app/id6740040672) | [安装扩展](https://chromewebstore.google.com/detail/bbhjjpgkahbphfmllckjjpkgpcaghgjk) | [安装扩展](https://addons.mozilla.org/firefox/addon/nolet/) | [安装扩展](https://microsoftedge.microsoft.com/addons/detail/cpeddmngdbglghhmfomfpeckcllgpcii) |

* 安装后点击扩展图标，输入你的推送密钥进行配置
* 支持一键发送当前页面、选中文本或图片到你的设备
* 特别适合将Instagram等网站的图片直接发送到手机


## 项目中使用的第三方库

* [Defaults](https://github.com/sindresorhus/Defaults)
* [QRScanner](https://github.com/mercari/QRScanner)
* [GRDB](https://github.com/groue/GRDB.swift.git)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [Kingfisher](https://github.com/onevcat/Kingfisher)
* [OpenAI](https://github.com/MacPaw/OpenAI)
* [Splash](https://github.com/AugustDev/Splash)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)