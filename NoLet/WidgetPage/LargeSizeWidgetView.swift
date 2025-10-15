//
//  LargeSizeWidgetView.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//
import SwiftUI
import Defaults
import Charts
import WidgetKit

struct LargeSizeWidgetView: View {
    var result:WidgetData
    @AppStorage("selectedGroup",store: DEFAULTSTORE) var selectGroup: String = "总计"
    let chartTint: Color =  .orange
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("nolet")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.accent)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 35)
            
            VStack(spacing: 15){
                
                
                Text(result.large?.title ?? "")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(result.large?.subTitle ?? "")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -8)
                
                if result.large?.result?.count ?? 0 > 1{
                    Picker(selection: $selectGroup) {
                        ForEach(result.large?.result ?? [], id: \.self) { item in
                            Text(item.group ?? "")
                                .font(.caption.bold())
                                .lineLimit(1)
                                .foregroundStyle(item.group == selectGroup ? .white : .primary)
                                .tag(item.group ?? "")
                        }
                    }label:{
                        Text("分组选择")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectGroup) { _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                }
                
                if let group = result.large?.result?.first(where: {$0.group == selectGroup}),let result = group.result{
                    
                    Chart(result) { item in
                        
                        if group.type == .pie {
                            /// NEW API
                            /// Pie/Donut Chart
                            if #available(iOS 17.0, *) {
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
                                }
                            } else {
                                // Fallback on earlier versions
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
                        } else {
                            BarMark(
                                x: .value("Name", item.name),
                                y: .value("Value", item.value)
                            )
                            .foregroundStyle(by: .value("Name", item.name))
                            .annotation(position: .top) {
                                Text(item.tips())
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.5)
                            }
                            
                            
                        }
                        if group.type == .bar, let lines = group.lines {
                            ForEach(lines, id: \.self) { item in
                                // 添加水平线，比如 y = 10000
                                RuleMark(y: .value("目标线", item))
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
        
        
        .padding()
        .animation(.default, value: selectGroup)
        .background26(.widget, radius: 20)
        .padding()
    }
}
