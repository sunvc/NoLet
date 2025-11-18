  
中文 ｜ **[English](README.EN.md)**

<p align="center">

<img src="/docs/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# NoLet
### An application designed for the iOS platform that allows you to push custom notifications to your Apple devices.

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-26.0-blue?logo=Xcode&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-5.10-red?logo=Swift&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-16.0+-green?logo=apple&logoColor=white" alt="NoLet App"></td>
  </tr>
</table>

| TestFlight | App Store | Documentation | Feedback Group |
|-------|--------|-------|--------|
|[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="NoLet App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="NoLet App" height="40">](https://apps.apple.com/app/id6615073345)| [User Documentation](https://wiki.wzs.app) | [NoLet](https://t.me/PushToMe) |


## Application Introduction

NoLet is a powerful iOS push tool that enables you to send custom notifications from any device to your iPhone/iPad. Whether it's server monitoring, script automation, or daily reminders, NoLet can meet all your needs.

> [!IMPORTANT]
>
>  - Simple and easy-to-use API with support for multiple request methods
>  - Support for large model configuration, translation, summary ...
>  - Markdown rendering support for richer push content
>  - Custom ringtones, remote icons, text icons, emoji icons, and images
>  - Multiple notification levels including time-sensitive and critical notifications
>  - Browser extension support for one-click sharing of web content
>  - Low-power design with minimal battery impact
>  - Open-source project with self-hosted server capability
>  - End-to-end encryption support for messages



|Markdown|Avatar And Image|
|-------|--------|
|<img src="/docs/_media/markdown.gif" width="350">|<img src="/docs/_media/avatarAndImage.gif" width="350">|
  

### Self-Hosted Push Server

* NoLet supports self-hosted servers to ensure data privacy and security
* Open-source server code: [NoLetServer](https://github.com/sunvc/NoLets)
* Self-hosted servers support multi-platform deployment (Windows, macOS, Linux, etc.)
* Docker containerized deployment support for easy maintenance and upgrades


## Browser Extensions

| Safari | Chrome | Firefox | Edge |
|-------|--------|---------|--------|
|  [MacOS](https://apps.apple.com/app/id6740040672)  | [Install Extension](https://chromewebstore.google.com/detail/bbhjjpgkahbphfmllckjjpkgpcaghgjk) | [Install Extension](https://addons.mozilla.org/firefox/addon/nolet/) | [Install Extension](https://microsoftedge.microsoft.com/addons/detail/cpeddmngdbglghhmfomfpeckcllgpcii) |

* After installation, click the extension icon and enter your push key to configure
* Supports one-click sending of the current page, selected text, or images to your device


## Third-Party Libraries Used in the Project

* [Defaults](https://github.com/sindresorhus/Defaults)
* [QRScanner](https://github.com/mercari/QRScanner)
* [GRDB](https://github.com/groue/GRDB.swift.git)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [Kingfisher](https://github.com/onevcat/Kingfisher)
* [OpenAI](https://github.com/MacPaw/OpenAI)
* [Splash](https://github.com/AugustDev/Splash)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)