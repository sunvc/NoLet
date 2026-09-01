//
//  PushParams.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/3/31.
//

import UserNotifications

/// 推送自定义字段字典（userInfo / 服务端请求参数）的键名。
///
/// 约定：
/// - 网络传参一律用 `name`（小写），如 `?level=critical&volume=5`；
/// - 服务端兼容驼峰/下划线/短横线等写法（SubTitle / sub_title / sub-title）；
/// - `title` / `subtitle` / `body` / `sound` 读取时优先取 `aps.alert` / `aps` 内的值，
///   其余字段直接取 userInfo 顶层。
enum Params: String, CaseIterable {
    /// 消息唯一标识（UUID 字符串）。
    /// 相同 id 覆盖已投递的消息；只传 id 且无标题/正文时删除对应消息。
    /// 用法：`?id=8F7A6C92-1B3A-4E2D-9F0A-7C6B5A493827`
    case id

    /// 推送标题。用法：`?title=服务器告警`
    case title

    /// 推送副标题。用法：`?subtitle=生产环境`
    case subtitle

    /// 推送正文。服务端兼容 content / message / data / text 等别名。
    /// 传 Markdown 源码需同时设置 `markdown`。用法：`?body=CPU 使用率 92%`
    case body

    /// 分组名，通知中心按组折叠、历史消息按组筛选；不传显示「默认」。
    /// 用法：`?group=运维告警`
    case group

    /// 点击通知跳转的地址，支持 http(s) Universal Link 与自定义 URL Scheme。
    /// 用法：`?url=https://example.com/incident/123`
    case url

    /// 通知分类 identifier，决定通知上的操作按钮。
    /// 使用自定义按钮时必传；值只能是固定的 `Identifiers` rawValue：
    /// `myNotificationCategory`（普通）、`markdown`，或 `alfa`…`zulu` 26 个自定义槽位
    /// （在 app 内为槽位配置按钮），不接受任意自定义分类名，如 `?category=alfa`。
    /// `markdown` / `reply` 等系统分类由对应字段自动推导，无需手动传。
    case category

    /// 中断级别。字符串或数字：`passive`(0) 静默不亮屏、`active`(1，默认)、
    /// `timeSensitive`(2) 可穿透专注模式、`critical`(3) 重要提醒可穿透静音；
    /// critical 模式下数字 3...10 同时兼作音量。用法：`?level=2`
    case level

    /// 消息存活时长。通知扩展按**秒**处理（Unix 时间戳增量），`-1` 永不过期，
    /// 不传则用 app 内默认过期设置。用法：`?ttl=3600`
    case ttl

    /// Markdown 正文：设置后正文按 Markdown 渲染，分类自动切换为 markdown。
    /// 用法：`?markdown=**粗体** 与 [链接](https://example.com)`（GET 需 URL 编码）
    case markdown

    /// 铃声名，不带 `.caf` 后缀（接收端自动补全）。
    /// 用法：`?sound=minuet`（app 内「铃声列表」可查看可用铃声）
    case sound

    /// critical 重要提醒的音量，取值 0...10，需配合 `level=critical`。
    /// 用法：`?level=critical&volume=8`
    case volume

    /// App 角标数字，任意整数；`<= 0` 清零并重置共享未读计数；
    /// 不传时由 app 未读计数自动维护。用法：`?badge=1`
    case badge

    /// 持续响铃（类微信来电）。
    /// - `"1"` / `true`：循环当前铃声至 30 秒；
    /// - 音频 URL：下载后作为长铃声播放；
    /// - 其他文本：走 TTS 语音播报该文本。
    /// 用法：`?call=1`
    case call

    /// 是否自动复制内容。`1` / `true` 开启；受系统限制需用户下拉/长按通知才触发。
    /// 复制的内容由 `copy` 指定。用法：`?autoCopy=1&copy=ABC123`
    case autoCopy

    /// 指定「复制」动作复制的文本；不传则复制整条通知内容。
    /// 用法：`?copy=一键复制这段验证码 888888`
    case copy

    /// 是否把 `image` 图片自动保存到系统相册，`1` / `true` 开启。
    /// 用法：`?image=https://example.com/a.png&saveAlbum=1`
    case saveAlbum

    /// 加密推送的密文，base64 编码，字节布局为 `12 字节 nonce + 密文 + 16 字节 GCM tag`。
    /// 携带后明文 title/subtitle/body 不再生效，由通知扩展解密填充。
    case cipherText

    /// 解密所用密钥在 app 密钥列表中的序号，默认 `0`（0 为系统默认密钥）。
    /// 用法：`?ciphertext=<base64>&cipherNumber=1`
    case cipherNumber

    /// 加密 IV/nonce 透传字段（服务端约定）。app 端约定 nonce 内嵌在密文前 12 字节，
    /// 自行加密推送时通常不需要传。
    case iv

    /// APNs 原生 `aps` 字典，内部字段：解密处理器用它重建 alert/sound 结构。
    case aps

    /// `aps.alert` 字典，`title` / `subtitle` / `body` 的读取来源。
    case alert

    /// 铃声文件扩展名常量（`"caf"`），拼接铃声文件名用，不是推送参数。
    case caf

    /// 正文渲染样式标记，如 `"markdown"`；归档消息据此选择渲染方式。
    case style

    /// 消息创建时间（Unix 秒），归档写入历史消息时由扩展生成。
    case createDate

    /// 已读标记，历史消息列表维护未读状态用。
    case read

    /// 兜底字段：不在 `names` 列表内的自定义键值会整体序列化存入 `other`，
    /// 供历史消息、插件、脚本读取，保证自定义字段不丢。
    case other

    /// 回复回调 URL：携带后通知出现文本输入框，用户回复时对该 URL 发起请求
    /// （回复文本追加在 URL 末尾）。用法：`?reply=https://example.com/reply`
    case reply

    /// 发送者图标，三种形式：图片 URL（自动缓存）、emoji（如 `🐲`）、
    /// 或「文字,颜色」组字（如 `组,ff0000`）；也支持 app 内云图标名称。
    /// 用法：`?icon=https://example.com/avatar.png`
    case icon

    /// 通知图片附件 URL，收到后由通知扩展下载并展示在通知卡片上。
    /// 用法：`?image=https://example.com/photo.png`
    case image

    /// 位置字段，两种模式：
    /// ① `"纬度,经度"`（如 `39.9,116.4`）：消息卡片显示地图按钮；
    /// ② 回调 URL：触发 Location 扩展获取定位后把位置 POST 回该 URL。
    case location

    /// 后台处理器脚本名（不含 `.js`，对应用户脚本的 processor 模式）。
    /// 推送到达时在通知扩展执行，只做副作用（转发 Webhook、写日志等），不改变通知显示。
    /// 用法：`?script=forward-alert`
    case script

    /// 通知内容插件脚本名（不含 `.js`，对应用户脚本的 plugin 模式）。
    /// 可在投递前修改通知内容或拦截通知。用法：`?plugin=my-plugin`
    case plugin

    /// 序列化后的键名（全小写）。
    var name: String { rawValue.lowercased() }

    /// 归档「已知推送参数」名单：归档消息时这些字段不进 `other` 兜底 JSON。
    static var names: [String] { allCases.prefix(27).compactMap { $0.name } }
}


extension Dictionary where Key == AnyHashable, Value == Any {
    subscript(key: Params) -> Any? {
        get { self[key.name] }
        set { self[key.name] = newValue }
    }

    private var apsObj: [AnyHashable: Any]? {
        self[.aps] as? [AnyHashable: Any]
    }

    private var alertObj: [AnyHashable: Any]? {
        apsObj?[.alert] as? [AnyHashable: Any]
    }

    func raw<T: ValueConvertible>(_ params: Params, as dataType: T.Type) -> T? {
        var value: Any? {
            switch params {
            case .title, .subtitle, .body:
                return alertObj?[params]
            case .sound:
                return apsObj?[params]
            default:
                return self[params]
            }
        }
        if let result = T.convert(from: value) {
            return result
        }
        return nil
    }
}

protocol ValueConvertible {
    static func convert(from value: Any?) -> Self?
}


extension String: ValueConvertible {
    static func convert(from value: Any?) -> String? {
        switch value {
        case let s as String:
            return s
        case let n as Int64:
            return String(n)
        case let b as Bool:
            return String(b)
        default:
            return nil
        }
    }
}

extension Int64: ValueConvertible {
    static func convert(from value: Any?) -> Int64? {
        switch value {
        case let n as Int64:
            return n
        case let s as String:
            return Int64(s)
        case let b as Bool:
            return b ? 1 : 0
        default:
            return nil
        }
    }
}

extension Bool: ValueConvertible {

    static func convert(from value: Any?) -> Bool? {

        switch value {

        case let value as Bool:
            return value

        case let value as Int:
            switch value {
            case 1:
                return true
            case 0:
                return false
            default:
                return nil
            }
            
        case let value as String:
            switch value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() {

            case "true", "yes", "y", "1":
                return true

            case "false", "no", "n", "0":
                return false

            default:
                return nil
            }

        default:
            return nil
        }
    }
}
