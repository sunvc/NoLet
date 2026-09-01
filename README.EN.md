  
中文 ｜ **[English](README.EN.md)**

<p align="center">

<img src="/docs/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# BravoPapa
### An application designed for the iOS platform that allows you to push custom notifications to your Apple devices.

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-26.0-blue?logo=Xcode&logoColor=white" alt="BravoPapa App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-5.10-red?logo=Swift&logoColor=white" alt="BravoPapa App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-16.0+-green?logo=apple&logoColor=white" alt="BravoPapa App"></td>
  </tr>
</table>

| TestFlight | App Store | Documentation | Feedback Group |
|-------|--------|-------|--------|
|[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="BravoPapa App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="BravoPapa App" height="40">](https://apps.apple.com/app/id6615073345)| [User Documentation](https://wiki.wzs.app) | [NoLet](https://t.me/PushToMe) |


## Application Introduction

BravoPapa is a powerful iOS push tool that enables you to send custom notifications from any device to your iPhone/iPad. Whether it's server monitoring, script automation, or daily reminders, NoLet can meet all your needs.

## ✨ Features

**Push & API**
- Simple, easy-to-use API supporting GET / POST / JSON, with parameter priority POST > GET > URL
- Bulk push (multiple devices via `device_keys`) and group push
- Send pushes directly via Siri Shortcuts
- MCP (Model Context Protocol) support
- Bark-style URL compatible

**Message Display**
- 5 message card templates: Default, Markdown, Terminal, GitHub, Payment — switched by `style`
- Rich Markdown rendering
- Title / subtitle / body / group; notifications are grouped by thread in Notification Center, and history can be browsed per group
- Message TTL with auto-expiry; same `id` overwrites or deletes a message
- Tap a notification to open a URL (URL Scheme and Universal Link supported)

**Notifications**
- 4 interruption levels: passive / active / time-sensitive / critical (critical can alert through Focus/mute with adjustable volume)
- Badge control and group muting
- Custom ringtones, remote ringtone download, TTS speech synthesis, call-style long ringtone
- In-notification text reply
- Custom notification categories and action buttons (alfa–zulu): built-in Copy / Mute group / Translate / Summarize, and custom buttons that can bind scripts
- Auto-copy and custom copy content

**Images & Media**
- Remote icons/avatars, emoji icons, text icons (text + color), cloud icons
- Image attachments downloaded and cached automatically, with optional auto-save to the photo album
- Map snapshots and location: pass coordinates to show a map directly; pass a callback URL to trigger a Location Push that fetches GPS in the background and posts it back
- Sender avatar shown in the notification (Intents contact donation)

**Security & Privacy**
- End-to-end encrypted push (multiple algorithms, custom keys)
- Fully open-source project with self-hosted server support (Docker, multi-platform) — your data stays under your control

**AI**
- Configurable large models for notification translation and summarization

**JavaScript Scripting**
- Built-in sandboxed JS runtime (fetch / crypto / storage / timers / console)
- Four script types: voice synthesis (tts), processor, action buttons, and notification plugin
- A notification plugin can fully take over the processing pipeline (decryption, attachments, sound, archiving, badge, etc. orchestrated by the script)

**More**
- Safari / Chrome / Firefox / Edge browser extensions for one-click sharing of pages, selected text, or images
- System share extension to push directly from other apps
- Low-power design with minimal battery impact



|Markdown|Avatar And Image|
|-------|--------|
|<img src="/docs/_media/markdown.gif" width="350">|<img src="/docs/_media/avatarAndImage.gif" width="350">|
  

### Self-Hosted Push Server

* BravoPapa supports self-hosted servers to ensure data privacy and security
* Open-source server code: [BravoPapaServer](https://github.com/sunvc/NoLets)
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
* [Kingfisher](https://github.com/onevcat/Kingfisher)
* [Splash](https://github.com/AugustDev/Splash)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)
* [swiftui-messaging-ui](https://github.com/FluidGroup/swiftui-messaging-ui)