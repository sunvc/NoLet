//
//  WidgetChartView.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//

import SwiftUI
import Defaults


enum WidgetMode:String, CaseIterable{
    case lock
    case small
    case medium
    case large
    
    
    var name:String{
        switch self {
        case .small:
            String(localized: "小号")
        case .medium:
            String(localized: "中号")
        case .large:
            String(localized: "大号")
        case .lock:
            String(localized: "锁屏")
        }
    }
}


struct WidgetChartView:View {
    @Default(.widgetData) var result
    @Default(.widgetURL) var widgetUrl
    @FocusState var showEdit:Bool
    @EnvironmentObject private var manager:AppManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectMode:WidgetMode  = .small
    
    init(data: String) {
        if let selectMode = WidgetMode(rawValue: data){
            self._selectMode = State(wrappedValue: selectMode)
        }
        
    }
    
    var body: some View {
        ScrollView {
            
            TextField("小组件更新地址", text: $widgetUrl, axis: .vertical)
                .focused($showEdit)
                .customField(icon: "network")
                .padding()
                .frame(minHeight: 100)
            
            Picker(selection: $selectMode) {
                ForEach(WidgetMode.allCases, id: \.self) { item in
                    Text(item.name)
                        .font(.caption.bold())
                        .lineLimit(1)
                        .foregroundStyle(item == selectMode ? .white : .primary)
                        .tag(item)
                }
            }label:{
                Text("小组件类别")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            
            HStack(alignment: .center){
                Spacer()
                switch selectMode {
                case .small:
                    SmallSizeWidgetView(result: result)
                        .transition(.move(edge: .bottom))
                case .medium:
                    MediumSizedWidget(result: result)
                        .transition(.move(edge: .bottom))
                case .large:
                    LargeSizeWidgetView(result: result)
                        .transition(.move(edge: .bottom))
                case .lock:
                    lockView
                        .transition(.move(edge: .bottom))
                }
                Spacer()
            }
            .frame(minHeight: windowWidth)
            .animation(.default, value: selectMode)
            
            
            
            
        }
        .toolbar {

            ToolbarItem(placement: .keyboard) {
                Button {
                    if !widgetUrl.hasHttp(){  self.widgetUrl = "" }
                    self.showEdit.toggle()
                } label: {
                    Text("完成")
                }

            }
            if let text = result.returnText(){
                ToolbarItem {
                    ShareLink("分享", item: text)
                }
            }
            
        }
        .onChange(of: scenePhase) { value in
            if value == .background{
                manager.router.removeLast()
            }
        }
    
        
    }
    

    
    private var lockView: some View{
        ZStack(alignment: .topTrailing) {
            Image("nolet")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 20)
                
            HStack{
                VStack(alignment: .leading) {
                   
                    Text(result.lock?.title ?? "")
                        .font(.caption2)
                        .lineLimit(1)
                    Text(result.lock?.subTitle ?? "")
                        .font(.callout)
                        .lineLimit(1)
                        
                }
                Spacer()
            }
        }
        .frame(width: 200,height: 50)
        .padding(10)
        .background26(.widget, radius: 20)

    }
}

