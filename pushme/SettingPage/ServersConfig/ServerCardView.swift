//
//  ServerCardView.swift
//  pushback
//
//  Created by uuneo 2024/10/30.
//

import SwiftUI
import Defaults




struct ServerCardView:View {
    @EnvironmentObject private var manager: AppManager
    @State private var textAnimation:Bool = false

	var item: PushServerModel
	var isCloud:Bool = false
    var complete:() -> Void
    
    var accessText: String{
        item.status ? String(localized: "服务器:") + item.url + String(localized: "状态正常"):
        String(localized: "服务器:") + item.url + String(localized: "状态异常")
    }


	var body: some View {
        VStack{

            HStack(spacing: 10){
                
                Group{
                    if !isCloud {
                        Image(systemName:  "externaldrive.badge.wifi")
                            .scaleEffect(1.5)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(item.status ? .green : .red, Color.primary)
                            .padding(.horizontal,5)
                            .if(!item.status){
                                $0.symbolEffect(.variableColor, delay: 1)
                            }
                    }else{
                        Image(systemName: "externaldrive.badge.icloud")
                            .scaleEffect(1.5)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.accent, Color.primary)
                            .padding(.horizontal,5)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    manager.router.append(.serverInfo(server: item))
                }


                
                VStack(alignment: .leading,spacing: 5){

                    HStack(alignment: .center){
                        Text( String(localized: "服务器") + ":")
                            .font(.caption2)
                            .frame(width:40, alignment: .trailing)
                            .foregroundStyle(.gray)

                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    Divider()
                    HStack(alignment: .center){
                        Text("KEY:")
                            .font(.caption2)
                            .frame(width:40, alignment: .trailing)
                            .foregroundStyle(.gray)
                        Text(item.key)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                }

                .if(true){ view in

                    Group{
                        if #available(iOS 26.0, *){
                            view
                                .onTapGesture {
                                    sharedSever()
                                    Haptic.impact()
                                }
                        }else{
                            view
                                .VButton(onRelease: { _ in
                                    sharedSever()
                                    return true
                                })
                        }
                    }

                }


                
                Spacer()
                
                if isCloud{
                    Image(systemName: "icloud.and.arrow.down")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .symbolEffect(.bounce,delay: 1)
                        .onTapGesture {
                            complete()
                        }
                }else {
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .symbolEffect(.bounce,delay: 1)
                        .onTapGesture {
                            complete()
                            self.textAnimation.toggle()
                        }
                }
                
                
            }
            
        }
        .padding(10)
        .background26(.message, radius: 15)
        .padding(.vertical, 5)
        .transaction { $0.animation = .snappy }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessText)
        .accessibilityAction(named: "分享"){
            let local = PBScheme.pb.scheme(host: .server, params: ["text": item.server])
            manager.sheetPage = .quickResponseCode(text: local.absoluteString, title: String(localized: "服务器配置"),preview: nil)
        }
        .accessibilityAction(named:isCloud ? "下载云服务器" : "复制"){
            complete()
        }
	}
    
    private func sharedSever(){
        var config:String?{
            if item.url.contains(BaseConfig.defaultServer){
                return nil
            }
            if let sign = item.sign,
               let crypto = CryptoModelConfig(inputText: sign),
               let result = crypto.obfuscator(sign: true) {
                return result
            }
            return nil
        }
        var params:[String: Any]{
            if let config = config, !item.url.contains(BaseConfig.defaultServer){
                return ["text": item.url, "sign": config]
            }
            return ["text": item.url]
        }
        let local = PBScheme.pb.scheme(host: .server, params: params)
        manager.sheetPage = .quickResponseCode(text: local.absoluteString,
                                               title: String(localized: "服务器配置"),
                                               preview: nil)
    }

}
