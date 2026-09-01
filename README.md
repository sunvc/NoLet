  
中文 ｜ **[English](README.EN.md)**

<p align="center">

<img src="/docs/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# BravoPapa 伞兵
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
|[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="NoLet App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="NoLet App" height="40">](https://apps.apple.com/cn/app/id6615073345)| [使用文档](https://wiki.wzs.app) | [NoLet](https://t.me/PushToMe) |


## 应用介绍

BravoPapa (伞兵)  是一款强大的iOS推送工具，让你能够从任何设备向iPhone/iPad发送自定义通知。无论是服务器监控、脚本自动化还是日常提醒，NoLet 伞兵都能满足你的需求。

## ✨ 功能特性

**推送接入**
- 简单易用的 API，支持 GET / POST / JSON，参数优先级 POST > GET > URL
- 批量推送（多设备 `device_keys`）、分组推送
- 支持 Siri 快捷指令直接发送推送
- 支持 MCP（Model Context Protocol）接入
- 兼容 Bark 风格 URL

**消息展示**
- 5 种消息卡片模板：默认、Markdown、终端 Terminal、GitHub、支付 Payment，按 `style` 切换
- Markdown 富文本渲染
- 标题 / 副标题 / 正文 / 分组，通知中心按分组聚合，历史消息可按群组查看
- 消息 TTL 过期自动消失；相同 `id` 覆盖或删除消息
- 点击通知跳转 URL（支持 URL Scheme 与 Universal Link）

**通知能力**
- 4 种中断级别：passive / active / 时效性通知 / 关键警告（critical 可在静音、专注模式提醒并调节音量）
- 角标 badge 控制、分组静音
- 自定义铃声、远程铃声下载、TTS 语音合成播报、来电式长提醒
- 通知内文本回复（reply）
- 自定义通知分类与操作按钮（alfa–zulu）：内置复制 / 静音分组 / 翻译 / 总结，自定义按钮可绑定脚本
- 自动复制、指定复制内容

**图片与媒体**
- 远程图标 / 头像、Emoji 图标、文字图标（文字+颜色）、云端图标
- 图片附件自动下载缓存，可自动保存到相册
- 地图快照与定位：传坐标直接显示地图；传回调 URL 触发 Location Push 后台获取 GPS 并回传
- 通知中显示发送者头像（Intents 联系人捐赠）

**安全与隐私**
- 消息端到端加密推送（多种算法、自定义密钥）
- 项目完全开源，可自建服务器（支持 Docker、多平台部署），数据自主可控

**AI 能力**
- 可配置大模型，支持通知翻译、内容摘要 / 总结

**JavaScript 脚本扩展**
- 内置沙盒 JS 运行时（fetch / crypto / storage / 定时器 / console）
- 四种脚本模式：语音合成（tts）、处理器（processor）、动作按钮（action）、通知插件（plugin）
- 通知插件可完全接管通知处理链（解密、附件、声音、落库、角标等由脚本编排）

**其他**
- Safari / Chrome / Firefox / Edge 浏览器扩展，一键分享网页、选中文本或图片
- 系统分享扩展，从其他 App 直接推送
- 低功耗设计，对电池影响极小



|Markdown|Avatar And Image|
|-------|--------|
|<img src="/docs/_media/markdown.gif" width="350">|<img src="/docs/_media/avatarAndImage.gif" width="350">|
  


### 自建推送服务器

* BravoPapa 伞兵支持自建服务器，保证数据隐私和安全
* 服务器代码开源：[BravoPapaServer](https://github.com/sunvc/NoLets)
* 自建服务器支持多平台部署（Windows、macOS、Linux等）
* 支持Docker容器化部署，便于维护和升级

## 浏览器扩展

| Safari | Chrome | Firefox | Edge |
|-------|--------|-------|--------|
| [MacOS](https://apps.apple.com/app/id6740040672) | [安装扩展](https://chromewebstore.google.com/detail/bbhjjpgkahbphfmllckjjpkgpcaghgjk) | [安装扩展](https://addons.mozilla.org/firefox/addon/nolet/) | [安装扩展](https://microsoftedge.microsoft.com/addons/detail/cpeddmngdbglghhmfomfpeckcllgpcii) |

* 安装后点击扩展图标，输入你的推送密钥进行配置
* 支持一键发送当前页面、选中文本或图片到你的设备


## 项目中使用的第三方库

* [Defaults](https://github.com/sindresorhus/Defaults)
* [QRScanner](https://github.com/mercari/QRScanner)
* [Kingfisher](https://github.com/onevcat/Kingfisher)
* [Splash](https://github.com/AugustDev/Splash)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)
* [swiftui-messaging-ui](https://github.com/FluidGroup/swiftui-messaging-ui)