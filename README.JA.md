  
中文 ｜ **[English](README.EN.md)** | **[日本語](README.JA.md)** | **[한국어](README.KO.md)**

<p align="center">

<img src="/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# NoLet 無字書
### iOSプラットフォーム向けに設計された、Appleデバイスにカスタム通知をプッシュできるアプリケーションです。

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-16.2-blue?logo=Xcode&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-5.10-red?logo=Swift&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-16.0+-green?logo=apple&logoColor=white" alt="NoLet App"></td>
  </tr>
</table>

| TestFlight | App Store | ドキュメント | フィードバックグループ |
|-------|--------|-------|--------|
|[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="NoLet App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="NoLet App" height="40">](https://apps.apple.com/app/id6615073345)| [使用ドキュメント](https://wiki.wzs.app) | [NoLet](https://t.me/PushToMe) |


## アプリケーション紹介

NoLet 無字書は強力なiOSプッシュツールで、任意のデバイスからiPhone/iPadにカスタム通知を送信できます。サーバー監視、スクリプト自動化、日常のリマインダーなど、NoLet 無字書があらゆるニーズにお応えします。

> [!IMPORTANT]
>
>  - シンプルで使いやすいAPI、複数のリクエスト方式をサポート
>  - Markdownレンダリングサポートで、より豊富なプッシュコンテンツを実現
>  - カスタム着信音、リモートアイコン、テキストアイコン、絵文字アイコン、画像
>  - 時間的制約や重要通知を含む複数の通知レベル
>  - ブラウザ拡張機能サポートで、ワンクリックでWebページコンテンツを共有
>  - 低消費電力設計で、バッテリーへの影響を最小限に抑制
>  - オープンソースプロジェクトで、独自サーバーの構築が可能
>  - メッセージのエンドツーエンド暗号化をサポート



|Markdown|Avatar And Image|
|-------|--------|
|<img src="/_media/markdown.gif" width="350">|<img src="/_media/avatarAndImage.gif" width="350">|
  

### 独自プッシュサーバーの構築

* NoLet 無字書は独自サーバーの構築をサポートし、データプライバシーとセキュリティを保証
* サーバーコードはオープンソース：[NoLetServer](https://github.com/sunvc/NoLets)
* 独自サーバーは複数プラットフォームでの展開をサポート（Windows、macOS、Linuxなど）
* Dockerコンテナ化展開をサポートし、メンテナンスとアップグレードが容易

## ブラウザ拡張機能

### Safari拡張機能

* Safari拡張機能は個別インストール不要で、アプリに内蔵
* iOSデバイスでアプリを開いた後、設定ページに移動し、指示に従ってSafari拡張機能を有効化
* 有効化後、Webブラウジング時にコンテンツを直接デバイスに共有可能

### Chrome拡張機能

* [Chrome拡張機能をインストール](https://chromewebstore.google.com/detail/NoLet/gadgoijjifgnbeehmcapjfipggiijeej)
* インストール後、拡張機能アイコンをクリックし、プッシュキーを入力して設定
* 現在のページ、選択したテキストや画像をワンクリックでデバイスに送信をサポート
* Instagramなどのウェブサイトの画像を直接スマートフォンに送信するのに特に適している


## プロジェクトで使用されているサードパーティライブラリ

* [Defaults](https://github.com/sindresorhus/Defaults)
* [QRScanner](https://github.com/mercari/QRScanner)
* [GRDB](https://github.com/groue/GRDB.swift.git)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [Kingfisher](https://github.com/onevcat/Kingfisher)
* [OpenAI](https://github.com/MacPaw/OpenAI)
* [Splash](https://github.com/AugustDev/Splash)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)