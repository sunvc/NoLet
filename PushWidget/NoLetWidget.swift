//
//  Widget.swift
//  Widget
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//   Created by Neo on 2025/5/6.
//

import WidgetKit
import SwiftUI
import Charts


let UserStore = UserDefaults(suiteName: NCONFIG.groupName)!


struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let result: WidgetData
}

struct Provider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), result: WidgetData.getDefault())
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async ->  SimpleEntry  {
        
        let cryptoData = await WidgetData.fetchData()
        return  SimpleEntry(date: .now, configuration: configuration, result: cryptoData)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry > {
        
        let cryptoData = await WidgetData.fetchData()
        
        let entry = SimpleEntry(date: .now, configuration: configuration, result: cryptoData)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: configuration.refreshIntervalMinutes, to: .now)
        return Timeline(entries: [entry], policy: .after(nextUpdate!))
    }
}

struct CryptoWidgetEntryView : View {
    var crypto: Provider.Entry
    // MARK: Use this Environment Property to find out the widget Family
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        // MARK: Building Widget UI With Swift Charts
        switch family{
        case .systemSmall:
            SmallSizeWidget(entry: crypto)
                .widgetURL(PBScheme.pb.scheme(host: .openPage, params: ["page":"widget","title":crypto.result.small?.title ?? "","data":"small"]))
        case .systemMedium:
            MediumSizedWidget(entry: crypto)
                .widgetURL(PBScheme.pb.scheme(host: .openPage, params: ["page":"widget","title":crypto.result.medium?.title ?? "","data":"medium"]))
        case .systemLarge, .systemExtraLarge:
            LargeSizeWidget(entry: crypto)
                .widgetURL(PBScheme.pb.scheme(host: .openPage, params: ["page":"widget","title":crypto.result.large?.title ?? "","data":"large"]))
        default:
            LockScreenWidget(entry: crypto)
                .widgetURL(PBScheme.pb.scheme(host: .openPage, params: ["page":"widget","title":crypto.result.lock?.title ?? "","data":"lock"]))
        }
    }
    
}

struct NoLetWidget: Widget {
    let kind: String = "NoLetCryptoWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            CryptoWidgetEntryView(crypto: entry)
                .containerBackground(.fill.tertiary, for: .widget)
            
        }
        .supportedFamilies([.systemMedium,.accessoryRectangular,.systemSmall,.systemLarge, .systemExtraLarge])
        .configurationDisplayName("自定义小组件")
        .description("自定义数据小组件")
    }
}



