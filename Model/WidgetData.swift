//
//  WidgetData.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//
import SwiftUI
import Defaults
import ActivityKit
import GRDB

extension Defaults.Keys{
    static let widgetData = Key<WidgetData>("widgetData",default: WidgetData.getDefault())
}

extension WidgetData: Defaults.Serializable{}

typealias WidgetDataType = Codable & Hashable & Equatable & Identifiable

enum ChartType:String,Codable{
    case pie
    case bar
}

struct WidgetData: WidgetDataType {
    var id = UUID()
    var small: Section<Item>?
    var medium: Section<Item>?
    var large: Section<Section<Item>>?
    var lock: Section<Item>?
    
    enum CodingKeys: CodingKey {
        case small
        case medium
        case large
        case lock
    }
    
    
    struct Section<T:WidgetDataType>: WidgetDataType {
        var id = UUID()
        var title:String?
        var subTitle:String?
        var group: String?
        var lines: [Int]?
        var sort: Int?
        var type: ChartType?
        var result: [T]?
        
        enum CodingKeys: CodingKey {
            case title
            case subTitle
            case group
            case lines
            case sort
            case type
            case result
        }
    }
    struct Item: WidgetDataType {
        var id = UUID()
        var name: String
        var value: Int
        var sort: Int?
        var unity: Int?
        func tips() -> String{
            guard let unity, unity > 0 else { return body }
            return value >= unity ? (Double(value) / Double(unity)).formattedWithOneDecimalAndSeparator() : body
        }
        var body:String{ value.withThousandsSeparator() }
        
        enum CodingKeys: CodingKey {
            case name
            case value
            case sort
            case unity
        }
    }
    
}

extension WidgetData{
    static let title = "PUSHBACK"
    static func subTitle()-> String {
        String(format: String(localized: "总计收到%1$d条"), Defaults[.allMessagecount])
    }
    static func getDefaultLarge() -> Section<Section<Item>> {
        
        func items(names:[String] = [],index:Int) -> [Item]{
            if names.isEmpty{
                return ["a","b","c","d","e","f"].map({name in
                    Item( name: name, value: Int.random(in: 0...10000), sort: index , unity: 1000)}
                )
            }
            
            return  names.map({name in
                Item( name: name, value: Int.random(in: 0...10000), sort: index , unity: 1000)}
            )
        }
        
        let names = [String(localized: "示例") + "1",String(localized: "示例") + "2",String(localized: "示例") + "3"]
        var results = names.indices.compactMap { index in
            let datas = items(index: index)
            
            let line = Int((datas.max { $0.value < $1.value }?.value ?? 1000) / 2)
            return Section( group: names[index],lines: [line], sort: index + 1, result: datas)
        }
        
        var datas:[Item] = []
        
        for index in results.indices{
            let item = results[index]
            datas.append(Item( name: item.group ?? "", value:  (item.result ?? []).reduce(0) { $0 + $1.value}, sort: 0, unity: 1000))
        }
        
        let line = Int((datas.max { $0.value < $1.value }?.value ?? 1000) / 2)
        
        results.append(Section( group: String(localized: "总计"), lines: [line], sort: 0,type: .pie, result: datas))
        
        
        results.sort(by: {$0.sort ?? 0 < $1.sort ?? 0 })
        
        return .init(title: WidgetData.title, subTitle:  WidgetData.subTitle() ,result: results)
        
    }
    static func getDefaultSmallOrMedium(_ isSmall:Bool = true) -> Section<Item>{
        
        let calendar = Calendar.current
        let now = Date()
        
        let unRead = MessagesManager.shared.unreadCount()
        
        // 分组个数
        
        let groups = MessagesManager.shared.queryGroup().count
        
        let total = MessagesManager.shared.count()
        
        // 本周
        let startOfWeek = calendar.startOfWeek(for: now)
        
        let weekMessages = try? DatabaseManager.shared.dbQueue.read ({ db in
            try Message.filter(Message.Columns.createDate > startOfWeek).fetchCount(db)
        })
//        let weekMessages = total.filter({$0.createdate > startOfWeek})
        
        // 本月
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthMessages = try? DatabaseManager.shared.dbQueue.read ({ db in
            try Message.filter(Message.Columns.createDate > startOfMonth).fetchCount(db)
        })
   
        /// 平均每天多少条
        let dayCount = calendar.dateComponents([.day], from: startOfMonth, to: now).day! + 1 // 避免除以 0
        let averagePerDay = Int(max(Double(monthMessages ?? 0) / Double(dayCount),1))
        
        let items:[Item] = [
            .init( name: String(localized: "总计"), value: total),
            .init( name: String(localized: "分组"), value: groups),
            .init( name: String(localized: "未读"), value: unRead),
            .init( name: String(localized: "本周"), value: weekMessages ?? 0),
            .init( name: String(localized: "本月"), value: monthMessages ?? 0),
            .init( name: String(localized: "日均"), value: averagePerDay),
        ]
        
        return WidgetData.Section(title: WidgetData.title, subTitle: WidgetData.subTitle(), result: isSmall ? Array(items.prefix(3)) : items)
    }
    static func getDefault() -> Self {
        
        
        
        
        return WidgetData(small: WidgetData.getDefaultSmallOrMedium(),
                   medium: WidgetData.getDefaultSmallOrMedium(false),
                   large: WidgetData.getDefaultLarge(),
                   lock:  WidgetData.Section(title: WidgetData.title, subTitle: WidgetData.subTitle()))
    }
    
    // MARK: Fetching JSON Data
    static func fetchData()async-> Self{
        
        let APIURL = Defaults[.widgetURL]
        
        guard let url = URL(string: APIURL) else {
            return  Self.getDefault()
        }
        
        let session = URLSession(configuration: .default)
        do{
            let response = try await session.data(from: url)
            var cryptoData = try JSONDecoder().decode(Self.self, from: response.0)
            
            if cryptoData.lock?.title?.count ?? 0  == 0 && cryptoData.lock?.subTitle?.count ?? 0 == 0{
                cryptoData.lock = .init(title: title, subTitle: "")
            }
            
            if cryptoData.small?.result?.count ?? 0 < 3 {
                cryptoData.small = WidgetData.getDefaultSmallOrMedium()
            }
            
            if cryptoData.medium?.result?.count ?? 0 < 6{
                cryptoData.medium = WidgetData.getDefaultSmallOrMedium(false)
            }
            
            if cryptoData.large?.result?.count ?? 0 < 1{
                cryptoData.large = WidgetData.getDefaultLarge()
            }
            Defaults[.widgetData] = cryptoData
            return cryptoData
        }catch{
            return Defaults[.widgetData]
        }
        
        
    }
    
    func returnText() -> String? {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let jsonData = try encoder.encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

extension Int {
    /// 返回带千分位分隔符的字符串（例如：1,234,567）
    func withThousandsSeparator()-> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","  // 可根据需要改为 "." 或空格
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    /// 返回千分位格式并保留 1 位小数的字符串（例如：1,234.5）
    func  formattedWithOneDecimalAndSeparator()-> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","     // 千分位分隔符
        formatter.maximumFractionDigits = 1   // 最多保留 1 位小数
        formatter.minimumFractionDigits = 0   // 最少保留 1 位小数
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
