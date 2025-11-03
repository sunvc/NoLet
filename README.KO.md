  
중문 ｜ **[English](README.EN.md)** | **[日本語](README.JA.md)** | **[한국어](README.KO.md)**

<p align="center">

<img src="/_media/egglogo.png" alt="NoLet" title="NoLet" width="100"/>

</p>

# NoLet 무자서
### iOS 플랫폼을 위해 설계된 애플 기기로 사용자 정의 알림을 푸시할 수 있는 애플리케이션입니다.

<table>
  <tr>
    <th style="border: none;"><strong>NoLet</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-26.0-blue?logo=Xcode&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-5.10-red?logo=Swift&logoColor=white" alt="NoLet App"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-16.0+-green?logo=apple&logoColor=white" alt="NoLet App"></td>
  </tr>
</table>

| TestFlight | App Store | 문서 | 피드백 그룹 |
|-------|--------|-------|--------|
|[<img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/fc/78/a0/fc78a0ee-dc6b-00d9-85be-e74c24b2bcb5/AppIcon-85-220-0-4-2x.png/512x0w.webp" alt="NoLet App" height="45"> ](https://testflight.apple.com/join/PMPaM6BR) | [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="NoLet App" height="40">](https://apps.apple.com/app/id6615073345)| [사용 문서](https://wiki.wzs.app) | [NoLet](https://t.me/PushToMe) |


## 애플리케이션 소개

NoLet 무자서는 강력한 iOS 푸시 도구로, 어떤 기기에서든 iPhone/iPad로 사용자 정의 알림을 보낼 수 있게 해줍니다. 서버 모니터링, 스크립트 자동화, 일상 알림 등 NoLet 무자서가 모든 요구사항을 충족시켜 드립니다.

> [!IMPORTANT]
>
>  - 간단하고 사용하기 쉬운 API, 다양한 요청 방식 지원
>  - Markdown 렌더링 지원으로 더 풍부한 푸시 콘텐츠 제공
>  - 사용자 정의 벨소리, 원격 아이콘, 텍스트 아이콘, 이모지 아이콘 및 이미지
>  - 시간 민감성 및 중요 알림을 포함한 다양한 알림 레벨
>  - 브라우저 확장 지원으로 웹페이지 콘텐츠 원클릭 공유
>  - 저전력 설계로 배터리에 미치는 영향 최소화
>  - 오픈소스 프로젝트로 자체 서버 구축 가능
>  - 메시지 종단간 암호화 지원



|Markdown|Avatar And Image|
|-------|--------|
|<img src="/_media/markdown.gif" width="350">|<img src="/_media/avatarAndImage.gif" width="350">|
  

### 자체 푸시 서버 구축

* NoLet 무자서는 자체 서버 구축을 지원하여 데이터 프라이버시와 보안을 보장합니다
* 서버 코드 오픈소스: [NoLetServer](https://github.com/sunvc/NoLets)
* 자체 서버는 다중 플랫폼 배포 지원 (Windows, macOS, Linux 등)
* Docker 컨테이너화 배포 지원으로 유지보수 및 업그레이드 편의성 제공

## 브라우저 확장

| Safari | Chrome | Firefox | Edge |
|-------|--------|---------|--------|
| 시스템 기본 제공 | [확장 설치](https://chromewebstore.google.com/detail/bbhjjpgkahbphfmllckjjpkgpcaghgjk) | [확장 설치](https://addons.mozilla.org/firefox/addon/nolet) | [확장 설치](https://microsoftedge.microsoft.com/addons/detail/cpeddmngdbglghhmfomfpeckcllgpcii) |

* 설치 후 확장 아이콘을 클릭하고 푸시 키를 입력하여 설정합니다
* 현재 페이지, 선택한 텍스트 또는 이미지를 기기로 한 번에 전송할 수 있습니다
* Instagram 등 웹사이트의 이미지를 휴대폰으로 바로 전송하기에 특히 적합합니다


## 프로젝트에서 사용된 서드파티 라이브러리

* [Defaults](https://github.com/sindresorhus/Defaults)
* [QRScanner](https://github.com/mercari/QRScanner)
* [GRDB](https://github.com/groue/GRDB.swift.git)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [Kingfisher](https://github.com/onevcat/Kingfisher)
* [OpenAI](https://github.com/MacPaw/OpenAI)
* [Splash](https://github.com/AugustDev/Splash)
* [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)