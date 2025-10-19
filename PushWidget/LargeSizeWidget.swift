//
//  LargeSizeWidget.swift
//  NoLet
//
//  Created by lynn on 2025/5/7.
//

import SwiftUI
import Charts
import AppIntents
import WidgetKit

/// Tab Button Intent
struct TabButtonIntent: AppIntent {
    static var title: LocalizedStringResource = "Tab Button Intent"
    @Parameter(title: "group", default: "")
    var group: String
    
    init() {}
    
    init(group: String) {
        self.group = group
    }
    
    func perform() async throws -> some IntentResult {
        DEFAULTSTORE.set(group, forKey: "selectedGroup")
        return .result()
    }
}

struct RefreshButtonIntent: AppIntent{
    static var title: LocalizedStringResource = "Title Button Intent"
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
    
}




struct LargeSizeWidget:View {
    var entry: Provider.Entry
    @AppStorage("selectedGroup",store: DEFAULTSTORE) var selectGroup: String = "总计"
    
    var body: some View {
        
        let chartTint: Color = entry.configuration.chartTint?.color ?? .orange
        
        ZStack(alignment: .topTrailing) {
            Image("nolet")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.accent)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 35)
            
            VStack(spacing: 15){
                
              
                Button(intent: RefreshButtonIntent()) {
                    VStack{
                        Text(entry.result.large?.title ?? "")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(entry.result.large?.subTitle ?? "")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, -8)
                    }
                }.buttonStyle(.plain)
               
                if entry.result.large?.result?.count ?? 0 > 1{
                    HStack(spacing: 0) {
                      
                        ForEach(entry.result.large?.result ?? [],id: \.group) { item in
                            Button(intent: TabButtonIntent(group: item.group ?? "")) {
                                Text(item.group ?? "")
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                    .foregroundStyle(item.group == selectGroup ? .white : .primary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background {
                       
                        GeometryReader {
                            let size = $0.size
                            let width = size.width / CGFloat(entry.result.large?.result?.count ?? 0)
                            
                            Capsule()
                                .fill(chartTint.gradient)
                                .frame(width: width)
                                .offset(x: width * CGFloat(entry.result.large?.result?.firstIndex(where: { $0.group == selectGroup }) ?? 0))
                        }
                    }
                    .frame(height: 28)
                    .background(.primary.opacity(0.15), in: .capsule)
                    .padding(.bottom)
                }
        
                if let group = entry.result.large?.result?.first(where: {$0.group == selectGroup}),
                let result = group.result {
                    Chart(result) { item in
                        var chartType:ChartType{
                            entry.configuration.isReverseChart ? (group.type == .pie ? .bar : .pie) : group.type ?? .bar
                        }
                        if chartType == .pie {
                            /// NEW API
                            /// Pie/Donut Chart
                            SectorMark(
                                angle: .value("Name", item.value),
                                innerRadius: .ratio(0),
                                angularInset:  1
                            )
                            .cornerRadius(8)
                            .foregroundStyle(by: .value("Name", item.name))
                            .annotation(position: .overlay) {
                                Text(item.tips())
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.3)
                            }
                        } else {
                            BarMark(
                                x: .value("Name", item.name),
                                y: .value("Value", item.value)
                            )
                            .foregroundStyle(by: .value("Name", item.name))
                            .annotation(position: .top) {
                                Text(item.tips())
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                            
                          
                        }
                        if chartType == .bar, let lines = group.lines {
                            ForEach(lines, id: \.self) { item in
                                // 添加水平线，比如 y = 10000
                                RuleMark(y: .value("Name", item))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(.red)
                                    .annotation(position: .trailing, alignment: .center, spacing: 5) {
                                        Text(verbatim: "\(item)")
                                            .font(.caption.bold())
                                            .foregroundStyle(chartTint)
                                    }
                            }
                        }
                    }
                }
               
            }
        }
    }
    
    
}
