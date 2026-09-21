  
[中文](README.md) ｜ **English**

<p align="center">

<img src="/docs/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# NoLet
### A native HarmonyOS push notification client that lets you send custom notifications to your HarmonyOS devices from any device.

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/HarmonyOS-NEXT-orange?logo=huawei&logoColor=white" alt="HarmonyOS NEXT"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/ArkTS-blue" alt="ArkTS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Language-中文%20%7C%20English-green" alt="Language"></td>
  </tr>
</table>

## Introduction

NoLet is a native HarmonyOS push notification client that lets you send custom notifications to your HarmonyOS devices from any device. Whether it's server monitoring, script automation, or daily reminders, NoLet can meet your needs.

This repository is the **native HarmonyOS version**, built with ArkTS / ArkUI and receiving push notifications in the background via Huawei Push Service (HMS Push).

## ✨ Features

**Push & API**
- Receives push notifications via Huawei Push Service (HMS Push), no foreground process required
- Simple, easy-to-use API supporting GET / POST / JSON
- Supports `nolet://` and `https://wzs.app` deep links

**Message Display**
- Rich Markdown rendering (formulas and code highlighting supported)
- Title / body / group; notifications are aggregated by group, and history can be browsed per group
- Message TTL with auto-expiry; the same `id` overwrites or deletes a message
- Tap a notification to open a URL

**Security & Encryption**
- End-to-end encrypted push (AES-GCM, with custom 128 / 192 / 256-bit keys)
- Encryption configs can be exported and imported via QR code or deep link

**Servers & Sync**
- Server management with registration, restore, and history
- Cloud history sync (AppGallery Connect cloud database, isolated per Huawei account)

**More**
- Quick send: auto-detects clipboard content on launch, with confirmation or auto-send
- LAN share (UDP broadcast, no pairing required)
- Chinese / English bilingual

## Self-Hosted Push Server

* NoLet supports self-hosted servers to ensure data privacy and security
* Open-source server code: [NoLetServer](https://github.com/sunvc/NoLets)
* Multi-platform deployment and Docker containerization for easy maintenance and upgrades

## Third-Party Libraries Used in the Project

* [lv-markdown-in](https://gitee.com/luvi/lv-markdown-in) — Markdown rendering engine
* [state_store](https://gitcode.com/openharmony-sig/state_store) — state management framework
* [AppGallery Connect](https://developer.huawei.com/consumer/cn/) — push, cloud database, and sign-in services
