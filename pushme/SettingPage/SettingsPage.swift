//
//  SettingsPage.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//


import SwiftUI
import Defaults


struct SettingsPage: View {

	@EnvironmentObject private var manager:AppManager
    
	
	@Default(.appIcon) var setting_active_app_icon
	
    @Default(.sound) var sound
	@Default(.servers) var servers
    @Default(.assistantAccouns) var assistantAccouns
    
    
	@State private var webShow:Bool = false
	@State private var showLoading:Bool = false
	@State private var showPaywall:Bool = false
	@State private var buildDetail:Bool = false
    
	var serverTypeColor:Color{

		let right =  servers.filter(\.status == true).count
		let left = servers.filter(\.status == false).count

		if right > 0 && left == 0 {
			return .green
		}else if left > 0 && right == 0{
			return .red
		}else {
			return .orange
		}
	}
    
	// 定义一个 NumberFormatter
	private var numberFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 2
		return formatter
	}


	var body: some View {
        List{



            if .ISPAD{
                ListButton {
                    Label( "消息", systemImage: "ellipsis.message")
                } action: {
                    Task{@MainActor in
                        manager.router = []
                    }
                    return true
                }
            }
            
           
            
            Section(header: Text("App配置") .textCase(.none)) {
                
                ListButton {
                    Label {
                        Text("服务器")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "externaldrive.badge.wifi")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(serverTypeColor, Color.primary)
                            .if(serverTypeColor == .red){view in
                                view.symbolEffect(.variableColor, delay: 0.5)
                            }
                    }
                } action: {
                    Task{@MainActor in
                        manager.router = [.server]
                    }

                    return true
                    
                }
                
                
                
                
                ListButton {
                    Label {
                        Text( "云图标")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        ZStack{
                            Image(systemName: "icloud")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(Color.primary)
                            Image(systemName: "photo")
                                .scaleEffect(0.4)
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent)
                                .offset(y: 2)
                        }
                    }
                } action: {
                    Task{@MainActor in
                        manager.sheetPage = .cloudIcon
                    }
                    return true
                }
                
                ListButton {
                    
                    Label {
                        Text( "智能助手")
                    } icon: {
                        Image("chatgpt")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 26)
                            .customForegroundStyle(.accent, .primary)
                    }
                    
                   
                } action:{
                    Task{@MainActor in
                        manager.router = [.assistantSetting(nil)]
                    }
                    return true
                }
                
                ListButton {
                    Label {
                        Text( "声音设置")
                    } icon: {
                        Image(systemName: "speaker.wave.2.circle")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } trailing: {
                    Text(sound)
                        .foregroundStyle(.gray)
                } action: {
                    Task{@MainActor in
                        manager.router = [.sound]
                    }
                    return true
                    
                }
                
                ListButton {
                    Label {
                        Text( "算法配置")
                    } icon: {
                        Image(systemName: "key.viewfinder")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, Color.primary)
                            .scaleEffect(0.9)
                    }
                } action: {
                    Task{@MainActor in
                        manager.router = [.crypto]
                    }
                    return true
                }

               
                ListButton {
                    Label {
                        Text( "数据管理")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "archivebox.circle")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action:{
                    Task{@MainActor in
                        manager.router = [.dataSetting]
                    }
                    return true
                }
                
               

                ListButton  {
                    Label {
                        Text( "更多设置")
                    } icon: {
                        Image(systemName: "dial.high")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task{@MainActor in
                        manager.router = [.more]
                    }
                    return true

                }

            }
            

            Section {
                
                ListButton {
                    Label {
                        Text( "关于无字书")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "exclamationmark.octagon")

                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task{@MainActor in
                        manager.router = [.about]
                    }
                    return true
                }

                
                if #available(iOS 18.0, *) {
                    ListButton {
                        Label {
                            
                            Text("开发者支持计划")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "creditcard.circle")
                            
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, Color.primary)

                        }
                    } action: {
                        Task{@MainActor in
                            manager.sheetPage = .paywall
                        }
                        return true
                    }
                }
                
            }header:{
                Text( "其他" )
                    .textCase(.none)
            }
            
            
        }
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.fullPage = .scan
                    Haptic.impact()
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, Color.primary)

                }

            }
        }

    }

   

}




#Preview {
	NavigationStack{
        SettingsPage()
			.environmentObject(AppManager.shared)
	}

}
