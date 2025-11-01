//
//  ExampleView.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import SwiftUI
import Defaults


struct ExampleView: View {
    @EnvironmentObject private var manager:AppManager
    @State private var username:String = ""
    @State private var title:String = ""
    @State private var pickerSelection:Int = 0
    @State private var showAlart = false
    @Default(.servers) var servers
    @Default(.cryptoConfigs) var cryptoConfigs
    
    @State private var showCustomMode:Bool = false
    
    var currentServer:PushServerModel{
        servers.count > pickerSelection ? servers[pickerSelection] : PushServerModel(url: NCONFIG.server)
    }
    
    @Default(.exampleCustom) var params
    @State private var mode:Bool = false
    var contentColor:Color = .cyan
    
   
    
    
    var body: some View {
        VStack{
            
            
            Group{
                if showCustomMode{
                    CustomKeyInputView()
                        .transition(.move(edge: .leading))
                }else{
                    customHelpItemView()
                        .transition(.move(edge: .trailing))
                }
            }.animation(.default, value: showCustomMode)
            
        }
        
        .listStyle(GroupedListStyle())
        .navigationTitle( "使用示例")
        .toolbar{
            ToolbarItem {
                Button{
                    withAnimation(.snappy) {
                        self.showCustomMode.toggle()
                    }
                   
                }label: {
                    Image(systemName: !showCustomMode ? "blinds.horizontal.open" : "roller.shade.open")
                        .symbolEffect(.replace)
                        .foregroundStyle(.primary, .green)
                }
            }
        }
    }
    
    @ViewBuilder
    private func selectServer()-> some View{
        if servers.count > 1{
            Section{
                HStack{
                    Spacer()
         
                    Picker(selection: $pickerSelection, label: Text("切换服务器")) {
                        ForEach(servers.indices, id: \.self){index in
                            let server = servers[index]
                            Text(server.name)
                                .tag(server.id)
                        }
                    }.pickerStyle(MenuPickerStyle())
                        .onChange(of: pickerSelection) { value in
                            Defaults[.exampleCustom].server = servers[value].server
                        }
                    
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
    
    @ViewBuilder
    func customHelpItemView() -> some View{
        List{
            selectServer()
            ForEach(createExample(cryptoData: cryptoConfigs.config()),id: \.id){ item in
                //            let server = servers[pickerSeletion >= servers.count ? 0 : pickerSeletion]
                let server = (pickerSelection >= 0 && pickerSelection < servers.count) ? servers[pickerSelection] : servers[0]
                let resultUrl = server.server + "/" +  item.params
                
                Section{
                    HStack{
                        HStack{
                            Image(systemName: "qrcode.viewfinder")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .padding(.trailing, 5)
                                
                            Text(item.title)
                                .font(.headline)
                                .fontWeight(.bold)
                        }.VButton( onRelease: { _ in
                            AppManager.shared.sheetPage = .quickResponseCode(text: resultUrl,title: item.title, preview: item.title)
                            return true
                        })
                       
                        Spacer()
                        
                       
                        
                        Image(systemName: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .padding(.horizontal)
                            .VButton( onRelease: { _ in
                                UIPasteboard.general.string = resultUrl
                                Toast.copy(title:  "复制成功")
                                return true
                            })
                        Image(systemName: "safari")
                            .scaleEffect(1.3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .VButton( onRelease: { _ in
                                if resultUrl.hasHttp, let url = URL(string: resultUrl) {
                                    UIApplication.shared.open(url)
                                }
                                return true
                            })
                    }
                    Text(resultUrl).font(.caption)
                    
                }header:{
                    item.header
                        .textCase(.none)
                    
                }footer:{
                    VStack(alignment: .leading){
                        item.footer
                        Divider()
                            .background(Color.blue)
                    }
                    
                }
                
                
            }
        }
        
        
    }
    
    @ViewBuilder
    func CustomKeyInputView()-> some View{
        Form{
            selectServer()
            
            Section{
                HStack{
                    Text("服务器") + Text(verbatim: ":")

                    TextField("输入服务器地址", text: $params.server)
                        .foregroundStyle(contentColor)
                }
                HStack{
                    Text("群组:")
                    
                    TextField("输入群组", text: $params.group)
                        .foregroundStyle(contentColor)
                }
                
                HStack{
                    Text("标题:")
                    
                    TextField("输入标题", text: $params.title)
                        .foregroundStyle(contentColor)
                }
                
                HStack{
                    Text("副标题") + Text(verbatim: ":")

                    TextField("输入副标题", text: $params.subTitle)
                        .foregroundStyle(contentColor)
                }
                
                HStack{
                    Text(verbatim: "URL")
                    TextField("输入跳转地址", text: $params.url)
                        .foregroundStyle(contentColor)
                }
                
                HStack{
                    Text("图标:")
                    TextField("输入图标地址", text: $params.icon)
                        .foregroundStyle(contentColor)
                }
                
                HStack{
                    Text("图片:")
                    TextField("输入图片地址", text: $params.image)
                        .foregroundStyle(contentColor)
                }
                
                HStack{
                    Group{
                        Text("内容") + Text(verbatim: ":")
                    }
                        .foregroundStyle(.accent)
                    TextEditor(text:  $params.body)
                        .lineLimit(10)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(contentColor)
                }
            }header: {
                Text("推送内容")
            }
            
            Section{
                
                
                if mode {
                    Picker(selection: $params.sound) {
                        ForEach(AudioManager.shared.allSounds(),id: \.self){ content in
                            Text(content).tag(content)
                        }
                    }label:{
                        Text("铃声")
                    }
                    
                    Toggle("持续响铃",isOn: Binding(get: {
                        params.call == "1"
                    }, set: { value in
                        params.call = value ? "1" : "0"
                    }))
                    
                    
                    Picker(selection: $params.level) {
                        ForEach(LevelTitle.allCases,id: \.self) { item in
                            Text(item.name).tag(item)
                        }
                    }label:{
                        Text("推送级别")
                    }
                    
                    if params.level == .critical{
                        HStack{
                            Text("音量 \(Int(params.volume) * 10) %")
                            Spacer()
                            Slider(value: $params.volume, in: 0...10, step: 1)
                        }
                    }
                    
                    Toggle("加密",isOn: Binding(get: {
                        params.cipherText != ""
                    }, set: { value in
                        params.cipherText = value ? "cipherText" : ""
                    }))
                    
                    
                    
                    HStack{
                        Text("保存天数:")
                        Spacer()
                        TextField(value: $params.ttl, format: .number) {
                            Text("保存天数")
                        }
                        .keyboardType(.numberPad)
                    }
                    
                    Picker(selection: $params.category) {
                        ForEach(Identifiers.allCases,id: \.self){ item in
                            Text(item.name).tag(item)
                        }
                    }label:{
                        Text("推送样式")
                    }
                    
                    HStack{
                        Text("推送角标:")
                        Spacer()
                        TextField(value: $params.badge, format: .number) {
                            Text("推送角标")
                        }
                        .keyboardType(.numberPad)
                    }
                    
                    HStack{
                        Text(verbatim: "ID")
                        TextField("输入ID", text: $params.id)
                            .foregroundStyle(contentColor)
                        Image(systemName: "dice")
                            .onTapGesture {
                                params.id = UUID().uuidString
                                Haptic.impact()
                            }
                    }
                }
            }header: {
                Toggle("显示设置",isOn: $mode)
            }footer: {
                VStack{
                    Button{
                        copyExample()
                    }label: {
                        HStack{
                            Spacer()
                            Label("复制示例", systemImage: "doc.on.doc")
                                .fontWeight(.bold)
                                .foregroundStyle(.white, .thinMaterial)
                            Spacer()
                        }
                        
                    }.buttonStyle(BorderedProminentButtonStyle())
                    
                    Button{
                        sendExample()
                    }label: {
                        HStack{
                            Spacer()
                            Label("发送通知", systemImage: "arrow.up.message")
                                .fontWeight(.bold)
                                .foregroundStyle(.white, .thinMaterial)
                            Spacer()
                        }
                        
                    }.buttonStyle(BorderedProminentButtonStyle())
                        .tint(.blue)
                    
                    Button{
                        safariExample()
                    }label: {
                        HStack{
                            Spacer()
                            Label("浏览器测试", systemImage: "safari")
                                .fontWeight(.bold)
                                .foregroundStyle(.white, .thinMaterial)
                            Spacer()
                        }
                        
                    }.buttonStyle(BorderedProminentButtonStyle())
                        .tint(.green)
                }
                .padding(.vertical)
               
            }
            
            
        }
        .simultaneousGesture(
            DragGesture().onEnded { trans in
                if trans.translation.height > 50{
                    self.hideKeyboard()
                }
            }
        )
        .multilineTextAlignment(.trailing)
    }
    
}


extension ExampleView{
    func createExample(cryptoData:CryptoModelConfig)-> [PushExampleModel]{
        
        let ciphertext = CryptoManager(cryptoData).encrypt(NCONFIG.testData)?.replacingOccurrences(of: "+", with: "%2B") ?? ""
        
        return [
            
            PushExampleModel(header: Text("点击右上角按钮可以复制测试URL、预览推送效果"),
                             footer: Text( """
                                 ‼️参数可单独使用
                                 * /内容 或者 /标题/内容
                                 * group: 分组名，不传显示 `默认`
                                 * badge： 自定义角标 可选值 -1...
                                 * ttl: 消息保存时间 可选值 0...
                                 """),
                             title: String(localized: "基本用法示例"),
                             params: String(localized: "标题/副标题/内容?group=默认&badge=1&ttl=1"),
                             index: 1),
            
            PushExampleModel(header: Spacer(),
                             footer: Text( "GET方法需要URIConponent编码"),
                             title: String(localized:"Markdown样式"),
                             params: "?markdown=%7C%20Name%20%20%20%7C%20Age%20%7C%20City%20%20%20%20%20%20%7C%0A%7C--------%7C-----%7C-----------%7C%0A%7C%20Alice%20%20%7C%2024%20%20%7C%20New%20York%20%20%7C%0A%7C%20Bob%20%20%20%20%7C%2030%20%20%7C%20San%20Francisco%20%7C%0A%7C%20Carol%20%20%7C%2028%20%20%7C%20London%20%20%20%20%7C%0A",
                             index: 2),

            PushExampleModel(header:
                                HStack{
                                    Button{
                                        manager.router = [.example, .sound]
                                    }label:{
                                        Text("铃声列表")
                                            .font(.callout)
                                            .padding(.horizontal, 10)
                                    }
                                    Spacer()
                                },
                             footer: Text( "可以为推送设置不同的铃声"),
                             title: String(localized:"推送铃声"),
                             params: "\(String(localized: "推送内容"))?sound=craft",
                             index: 3),

            PushExampleModel(header:
                                HStack{
                                    Button{
                                        manager.sheetPage = .cloudIcon
                                    }label:{
                                        Text("云图标")
                                            .font(.callout)
                                            .padding(.horizontal, 10)
                                    }

                                    Text( "自定义推送显示的logo")
                                    Spacer()
                                },
                             footer: Spacer(),
                             title: String(localized:"自定义icon"),
                             params:  "\(String(localized: "推送内容"))?icon=\(NCONFIG.logoImage)",
                             index: 5),
            
            PushExampleModel(header: Text("可对通知设置中断级别"),
                             footer: Text( """
                             可选参数值:
                             - passive：仅添加到列表，不会亮屏提醒
                             - active： 默认值，系统会立即亮屏显示通知。
                             - timeSensitive:  时效性通知,专注模式下可显示通知。
                             - critical: ‼️重要提醒，静音或专注模式可正常提醒
                             * 参数可使用 0-10代替，具体查看文档
                             """),
                             title: String(localized:"通知类型"),
                             params: "\(String(localized:  "重要提醒通知,70%音量"))?level=critical&volume=7",
                             index: 6),

            PushExampleModel(header: Text("URLScheme或者网址"),
                             footer: Text( "点击跳转app"),
                             title: String(localized:"跳转第三方"),
                             params:  "\(String(localized: "推送内容"))?url=weixin://",
                             index: 7),

            PushExampleModel(header: Text( "持续响铃"),
                             footer: Text("通知铃声将持续播放30s，同时收到多个将按顺序依次响铃"),
                             title:  String(localized:"持续响铃"),
                             params: "\(String(localized:  "持续响铃"))?call=1",
                             index: 8),
            
            PushExampleModel(header: Text( "下拉消息会显示图片"),
                             footer: Text( "携带一个image,会自动下载缓存"),
                             title:  String(localized: "携带图片"),
                             params:  "?title=\(String(localized: "标题" ))&body=\(String(localized: "内容" ))&image=\(NCONFIG.logoImage)",
                             index: 9),

            PushExampleModel(header:
                                HStack{
                                    Text( "需要在")
                                    Button{
                                        manager.router = [.example, .crypto]
                                    }label:{
                                        Text("算法配置")
                                            .font(.callout)
                                            .padding(.horizontal, 10)
                                    }
                                    Text("中进行配置")
                                },
                             footer: Text( "加密后请求需要注意特殊字符的处理"),
                             title: String(localized: "端到端加密推送"),
                             params: "?ciphertext=\(ciphertext)",
                             index: 10),
            
        ]
    }
    func copyExample(){
        let param = params.createParams()
        
        Clipboard.set(param)
                                
        Toast.success(title: "复制成功")
    }
    
    func sendExample(){
        let query = params.getParams()
        let http = NetworkManager()
        
        Task{
            let res:APIPushToDeviceResponse? = try await http.fetch(url: params.server,
                                                                    method: .POST,
                                                                    params: query)
            if res?.code == 200{
                Toast.success(title:  "操作成功")
            }else{
                Toast.error(title: "操作失败")
            }
        }
       
    }
    
    func safariExample(){
        
        let param = params.createParams()
        if let url = URL(string: param){
            AppManager.openUrl(url: url, .safari)
        }else{
            Toast.error(title: "参数错误")
        }
    }
    
   
}

