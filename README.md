  
中文 ｜ **[English](README.EN.md)**

<p align="center">

<img src="/docs/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# NoLet 伞电
### 一款 HarmonyOS 原生推送通知客户端，让你从任意设备向鸿蒙设备发送自定义通知。

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/HarmonyOS-NEXT-orange?logo=huawei&logoColor=white" alt="HarmonyOS NEXT"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/ArkTS-blue" alt="ArkTS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/语言-中文%20%7C%20English-green" alt="语言"></td>
  </tr>
</table>

## 应用介绍

NoLet（伞电）是一款 HarmonyOS 原生推送通知客户端，让你能从任何设备向鸿蒙设备发送自定义通知。无论是服务器监控、脚本自动化还是日常提醒，NoLet 都能满足你的需求。

本仓库是 **HarmonyOS 原生版本**，基于 ArkTS / ArkUI 开发，通过华为推送服务（HMS Push）在后台接收推送。

## ✨ 功能特性

**推送接入**
- 基于华为推送服务（HMS Push）接收推送，无需常驻前台
- 简单易用的 API，支持 GET / POST / JSON
- 支持 `nolet://` 与 `https://wzs.app` 深链

**消息展示**
- Markdown 富文本渲染（支持公式与代码高亮）
- 标题 / 正文 / 分组，通知按分组聚合，历史消息可按群组查看
- 消息 TTL 过期自动消失；相同 `id` 覆盖或删除消息
- 点击通知跳转 URL

**安全与加密**
- 消息端到端加密推送（AES-GCM，支持 128 / 192 / 256 位自定义密钥）
- 加密配置可通过二维码或深链导出、导入

**服务器与同步**
- 服务器管理，支持注册、恢复与历史
- 云端历史同步（AppGallery Connect 云数据库，按华为账号隔离）

**其他**
- 快捷发送：进入应用自动检测剪贴板，弹窗确认或自动发送
- 局域网快传（UDP 广播，无需配对）
- 中文 / English 双语

## 自建推送服务器

* NoLet 支持自建服务器，保证数据隐私与安全
* 服务器代码开源：[NoLetServer](https://github.com/sunvc/NoLets)
* 支持多平台部署与 Docker 容器化，便于维护和升级

## 项目中使用的第三方库

* [lv-markdown-in](https://gitee.com/luvi/lv-markdown-in) —— Markdown 渲染引擎
* [state_store](https://gitcode.com/openharmony-sig/state_store) —— 状态管理框架
* [AppGallery Connect](https://developer.huawei.com/consumer/cn/) —— 推送、云数据库与登录服务
