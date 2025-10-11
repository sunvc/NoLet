//
//  OtherModel.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import SwiftUI
import Defaults
import Foundation



// MARK: - Remote Response
struct baseResponse<T>: Codable where T: Codable{
	var code:Int
	var message:String
	var data:T?
	var timestamp:Int?
}

struct DeviceInfo: Codable {
	var deviceKey: String
	var deviceToken: String

	// 使用 `CodingKeys` 枚举来匹配 JSON 键和你的变量命名
	enum CodingKeys: String, CodingKey {
		case deviceKey = "key"
		case deviceToken = "token"
	}
}

enum requestHeader :String {
	case https = "https://"
	case http = "http://"
}

enum Identifiers:String, CaseIterable, Codable {
    case myNotificationCategory
    case markdown

    enum Action:String, CaseIterable, Codable{
        case copyAction = "copy"
        case muteAction = "mute"
        
        var title:String{
            switch self {
            case .copyAction:
                String(localized: "复制")
            case .muteAction:
                String(localized: "静音分组1小时")
            }
        }
        var icon:String{
            switch self {
            case .copyAction:
                "doc.on.doc"
            case .muteAction:
                "speaker.slash"
            }
        }
    }
    
    static func setCategories(){

        let actions =  Action.allCases.compactMap { item in
            UNNotificationAction(identifier: item.rawValue, title: item.title, options: [.foreground], icon: .init(systemImageName: item.icon))
        }

        let categories = Self.allCases.compactMap { item in
            UNNotificationCategory(identifier: item.rawValue, actions: actions,
                                   intentIdentifiers: [],  options: [.hiddenPreviewsShowTitle])
        }

        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }


    var name:String{
        switch self {
        case .myNotificationCategory:
            return String(localized: "普通内容")
        case .markdown:
            return String(localized: "Markdown")
        }
    }
}



// MARK: - MessageAction model

enum MessageAction: String, CaseIterable, Equatable{
	case lastHour
	case lastDay
	case lastWeek
	case lastMonth
	case allTime
	case cancel
	
	var title:String{
		switch self {
		case .lastHour: String(localized: "一小时前")+String(localized: "的消息")
		case .lastDay: String(localized: "一天前")+String(localized: "的消息")
		case .lastWeek: String(localized: "一周前")+String(localized: "的消息")
		case .lastMonth: String(localized: "一月前")+String(localized: "的消息")
		case .allTime: String(localized: "所有消息")
		case .cancel: String(localized: "取消")
		}
	}
	
	var date:Date{
		switch self {
		case .lastHour: Date().someHourBefore(1)
		case .lastDay: Date().someDayBefore(0)
		case .lastWeek: Date().someDayBefore(7)
		case .lastMonth: Date().someDayBefore(30)
		case .allTime: Date()
		default: Date().s1970
		}
	}
	
}


// MARK: - QuickAction model

enum QuickAction: String, CaseIterable{
    
    case assistant
    case scan
    
    static func allShortcutItems(showAssistant:Bool) -> [UIApplicationShortcutItem] {
        
        var items = [UIApplicationShortcutItem(
            type: Self.scan.name,
            localizedTitle: String(localized:  "扫描二维码"),
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "qrcode.viewfinder"),
            userInfo: ["name": assistant.name as NSSecureCoding]
        )]
        
        if showAssistant{
            items.insert(UIApplicationShortcutItem(
                type: Self.assistant.name,
                localizedTitle: String(localized:  "问智能助手"),
                localizedSubtitle: "",
                icon: UIApplicationShortcutIcon(systemImageName: "message.and.waveform"),
                userInfo: ["name": scan.name as NSSecureCoding]
            ), at: 0)
        }
        return items
        
    }
    var name: String{ self.rawValue.lowercased() }
}

// MARK: - PushServerModel

struct PushServerModel: Codable, Identifiable, Equatable, Hashable{
	var id:String = UUID().uuidString
    var device:String
	var url:String
	var key:String = ""
	var status:Bool = false
	var createDate:Date = .now
	var updateDate:Date = .now
    var voice: Bool = false
    var sign:String? = nil
    
    init(id: String = UUID().uuidString, device: String? = nil, url: String, key: String = "", status: Bool = false, createDate: Date = .now, updateDate: Date = .now, voice: Bool = false, sign:String? = nil) {
        self.id = id
        self.device = device ?? BaseConfig.deviceInfoString()
        self.url = url
        self.key = key
        self.status = status
        self.createDate = createDate
        self.updateDate = updateDate
        self.voice = voice
        self.sign = sign
    }

	var name:String{
		var name = url
		if let range = url.range(of: "://") {
		   name.removeSubrange(url.startIndex..<range.upperBound)
		}
		return name
	}
	
	var color: Color{ status ? .green : .orange }
    var server:String{
        return self.url + "/" + self.key
    }
}



// MARK: - BadgeAutoMode

enum BadgeAutoMode:String, CaseIterable {
	case auto = "Auto"
	case custom = "Custom"
}




// MARK: - AppIconMode

enum AppIconEnum:String, CaseIterable, Equatable{
    case pushback
    case pushback1
    case pushback2
    
    var name: String? { self == .pushback ? nil : self.rawValue }
    
    var logo: String{
        switch self {
        case .pushback: "logo"
        case .pushback1: "logo1"
        case .pushback2: "logo2"
        }
    }
}

// MARK: - PushExampleModel

struct PushExampleModel:Identifiable {
	var id = UUID().uuidString
	var header,footer: AnyView
    var title:String
	var params:String
	var index:Int


    init<Header: View, Footer: View>(
        header: Header,
        footer: Footer,
        title: String,
        params: String,
        index: Int
    ) {
        self.header = AnyView(header)
        self.footer = AnyView(footer)
        self.title = title
        self.params = params
        self.index = index
    }

}



// MARK: - ExpirationTime

enum DefaultBrowserModel: String, CaseIterable {
	case safari
	case app

	var title:String{
        self == .safari ? "Safari" : String(localized: "内部")
	}

}


struct AssistantAccount: Codable, Identifiable, Equatable, Hashable{
    var id:String = UUID().uuidString
    var current:Bool = false
    var timestamp:Date = .now
    var name:String = String(localized: "智能助手")
    var host:String
    var basePath:String
    var key:String
    var model:String
    
    func toBase64() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }
    
    init( current: Bool = false, name: String = String(localized: "智能助手"), host: String, basePath: String, key: String, model: String) {
        self.current = current
        self.name = name
        self.host = host
        self.basePath = basePath
        self.key = key
        self.model = model
    }
    
    
    init?(base64: String) {
        guard let data = Data(base64Encoded: base64), let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        self = decoded
        self.id = UUID().uuidString
    }
    
    
    

}


extension AssistantAccount{
    mutating func trimAssistantAccountParameters() {
        name = name.trimmingSpaceAndNewLines
        host = host.trimmingSpaceAndNewLines
        host = host.removeHTTPPrefix()
        basePath = basePath.trimmingSpaceAndNewLines
        key = key.trimmingSpaceAndNewLines
        model = model.trimmingSpaceAndNewLines
    }

}


enum OutDataType{
    
    case text(String)
    case crypto(String)
    case server(url: String,key: String?, sign:String?)
    case otherUrl(String)
    case assistant(String)
    case page(page:pageType, title:String?, data:String)
    
    enum pageType: String {
        case widget
        case icon
    }
}


enum ExpirationTime: Int, CaseIterable, Equatable{
    case forever = 999999
    case month = 30
    case weekDay = 7
    case oneDay = 1
    case no = 0

    var days: Int{ self.rawValue }
    
    var title:String{
        switch self {
        case .no: String(localized: "不保存")
        case .oneDay: String(localized:"1天")
        case .weekDay: String(localized:"1周")
        case .month: String(localized:"1月")
        case .forever: String(localized: "长期")
        }
    }
    
    
}


struct SelectMessage: Codable{
    
    var id:UUID = UUID()
    var group:String
    var createDate:Date
    var title:String?
    var subtitle:String?
    var body:String?
    var icon:String?
    var url:String?
    var image:String?
    var from:String?
    var host:String?
    var level:Int = 1
    var ttl:Int = ExpirationTime.forever.days
    var read:Bool = false
    var search:String

}




enum PBScheme: String, CaseIterable{
    case pb
    case mw
    static var schemes:[String]{ Self.allCases.compactMap({ $0.rawValue }) }
    
    enum HostType: String{
        case server
        case crypto
        case assistant
        case openPage
        case widget
    }
    
    // pb://openpage?title=string or mw://openpage?title=string
    func scheme(host: HostType, params parameters: [String: Any]) -> URL {
        var components = URLComponents()
        components.scheme = self.rawValue
        components.host = host.rawValue // 固定 host，如果有 path 也可以加上
        
        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        
        return components.url!
    }
    
}

struct MoreMessage:Codable,Hashable{
    var createDate:Date
    var id:String
    var body:String
    var index:Int
    var count:Int
}



struct PushToTalkGroup: Codable, Hashable{
    var id: UUID
    var name: String
    var avatar: URL?
    var active: Bool
    private(set) var prefix: Int = 10
    private(set) var suffix: Int = 1
    
    var uiimage:UIImage?{
        if let avatar{
            UIImage(contentsOfFile: avatar.absoluteString)
        }else{
            UIImage(contentsOfFile: "logo2")
        }
    }
    
    mutating func set(_ prefix: Int? = nil, suffix: Int? = nil){
        if let prefix {
            self.prefix = max(min(prefix, 999), 10)
        }
        if let suffix{
            self.suffix = max(min(suffix, 999), 1)
        }
    }
    
}




enum TipsSound: String {
    case pttconnect
    case pttnotifyend
    case cbegin
    case bottle
    case qrcode
    case share
    case toolSent
    case pull
    case refresh
    case tabSelection
    case number
}
