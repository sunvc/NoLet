//
//  SelectMessageView.swift
//  pushback
//
//  Created by lynn on 2025/5/2.
//
import SwiftUI
import Kingfisher
import Defaults
import OpenAI

enum SelectMessageViewMode:Int, Equatable{
    case translate
    case abstract
    case raw
}


struct SelectMessageView:View {
    var message:Message
    var dismiss:() -> Void
    @StateObject private var chatManager = openChatManager.shared
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.translateLang) var translateLang
    
    @State private var scaleFactor: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    
    // 设定基础字体大小
    @ScaledMetric(relativeTo: .body) var baseTitleSize: CGFloat = 17
    @ScaledMetric(relativeTo: .subheadline) var baseSubtitleSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) var basedateSize: CGFloat = 13
    
    @StateObject private var manager = AppManager.shared
    
    @State private var image:UIImage? = nil
    
    @State private var isDismiss:Bool = false
    @State private var messageShowMode:SelectMessageViewMode = .raw
    @State private var translateResult:String = ""
    
    @State private var abstractResult:String = ""
    
    @State private var showAssistantSetting:Bool = false
    
    @State private var showOther:Bool = false
    
    @State private var cancels:CancellableRequest? = nil
    
    var body: some View {
       
            ScrollView{
                
                VStack{
                    
                    VStack{
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                                .zoomable()
                                .contextMenu{
                                    Section {
                                        Button {
                                            image.bat_save(intoAlbum: nil) { success, status in
                                                if status == .authorized || status == .limited{
                                                    if success{
                                                        Toast.success(title: "保存成功")
                                                    }else{
                                                        Toast.question(title: "保存失败")
                                                    }
                                                }else{
                                                    Toast.error(title: "没有相册权限")
                                                }
                                                
                                            }
                                        } label: {
                                            Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                                                .symbolRenderingMode(.palette)
                                                .customForegroundStyle(.accent, .primary)
                                        }
                                    }
                                }
                            
                        }
                    }
                    .padding(.top, UIApplication.shared.topSafeAreaHeight)
                    .zIndex(1)
                    
                    VStack{
                        HStack{
                            
                            VStack(alignment: .leading, spacing: 5){
                                
                                Text(message.createDate.formatString())
                                
                                if let host = message.host{
                                    Text(host.removeHTTPPrefix())
                                }
                            }
                            .font(.system(size: basedateSize * scaleFactor))
                            
                            Spacer()
                        }
                        .padding(.vertical)
                        
                        
                        if messageShowMode == .abstract{
                            VStack{
                                if abstractResult.isEmpty{
                                    Label("正在处理中...", systemImage: "rays")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
                                        .symbolEffect(.rotate)
                                }else{
                                    MarkdownCustomView(content: abstractResult, searchText: "", scaleFactor: scaleFactor)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 5)
                                        
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay {
                                ColoredBorder(cornerRadius: 5)
                            }
                            
                        }
                               
                        
                        if messageShowMode == .translate{
                            
                            VStack{
                                if translateResult.isEmpty{
                                    Label("正在处理中...", systemImage: "rays")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
                                        .symbolEffect(.rotate)
                                }else{
                                    MarkdownCustomView(content: translateResult, searchText: "", scaleFactor: scaleFactor)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 5)
                                       
                                }
                               
                            }
                            
                        }else{
                           
                            
                            if let title = message.title{
                                HStack{
                                    Spacer(minLength: 0)
                                    Text(title)
                                        .font(.system(size: baseTitleSize * scaleFactor))
                                        .fontWeight(.bold)
                                        .textSelection(.enabled)
                                    Spacer(minLength: 0)
                                }
                            }
                            
                            if let subtitle = message.subtitle{
                                HStack{
                                    Spacer(minLength: 0)
                                    Text(subtitle)
                                        .font(.system(size: baseSubtitleSize * scaleFactor))
                                        .fontWeight(.bold)
                                    Spacer(minLength: 0)
                                }
                            }
                            
                            Line()
                                .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5, 3]))
                                .padding(.horizontal, 3)
                            
                            if let body = message.body{
                                HStack{
                                    MarkdownCustomView(content: body, searchText: "", scaleFactor: scaleFactor)
                                        .textSelection(.enabled)
                                    Spacer(minLength: 0)
                                }
                            }
                            
                           
                            
                            if let other = message.other{
                                Divider()
                                    .padding(.top, 10)
                                DisclosureGroup("其他字段", isExpanded: $showOther){
                                    HStack{
                                        MarkdownCustomView(content: other, searchText: "", scaleFactor: scaleFactor)
                                            .textSelection(.enabled)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill( .gray.opacity(0.1))
                                    )
                                    Divider()
                                    
                                }
                               
                            }
                            
                            
                        }
                        
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .gesture(
                        MagnificationGesture()
                            .onChanged({ value in
                                let delta = value / lastScaleValue
                                lastScaleValue = value
                                scaleFactor *= delta
                                scaleFactor = min(max(scaleFactor, 1.0), 3.0) // 限制最小/最大缩放倍数
                            })
                            .onEnded{ _ in
                                lastScaleValue = 1.0
                            }
                    )
                    
                    
                    
                }
                .frame(width: windowWidth)
                .padding(.top, 30)
                .onAppear{
                    Task(priority: .userInitiated) {
                        if let image = message.image,
                           let file =  await ImageManager.downloadImage(image) {
                            self.image = UIImage(contentsOfFile: file)
                        }
                    }
                }
                .onChange(of: translateLang) { value in
                    self.translateResult = ""
                    self.abstractResult = ""
                    self.messageShowMode = .raw
                }
                
            }
            .toolbar{
                ToolbarItem(placement: .topBarLeading) {
                    Picker("选择翻译语言", selection: $translateLang) {
                        ForEach(Multilingual.commonLanguages, id: \.id) { country in

                            Text("\(country.flag)  \(country.name)")
                                .tag(country)
                        }
                    }
                    .pickerStyle(.menu)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()){
                            self.dismiss()
                        }
                        Haptic.impact(.light)
                    }) {

                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }



                ToolbarItem(placement: .bottomBar) {

                    Button{

                        Task(priority: .userInitiated) {

                            var text:String = ""
                            switch messageShowMode {
                            case .translate:
                                text = PBMarkdown.plain(translateResult)
                            case .abstract:
                                text = abstractResult
                            case .raw:
                                text = message.voiceText
                            }
                            guard !text.isEmpty else { return }
                            guard let player = await AudioManager.shared.speak(text) else {
                                return
                            }
                            AudioManager.setCategory(true, .playback, mode: .default)
                            player.play()
                        }
                    }label:{
                        Image(systemName: "speaker.wave.2.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .accessibilityLabel("朗读内容")
                    }

                }

                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                }


                ToolbarItem(placement: .bottomBar) {

                    Button{
                        if messageShowMode == .translate{
                            self.messageShowMode = .raw
                        }else{
                            self.messageShowMode = .translate
                            translateMessage()
                        }
                        Haptic.impact()

                    }label: {

                        HStack{
                            if #available(iOS 17.4, *){
                                Image(systemName: messageShowMode == .translate ?  "eye.slash" : "translate")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.accentColor, Color.primary)

                            }else{
                                Image(systemName: messageShowMode == .translate ?  "eye.slash" : "globe.europe.africa")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.accentColor, Color.primary)
                            }

                            Text(messageShowMode == .translate ?  "隐藏" : "翻译")
                        }
                        .contentShape(Rectangle())

                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button{

                        if self.messageShowMode == .abstract{
                            self.messageShowMode = .raw
                        }else{
                            self.messageShowMode = .abstract
                            abstractMessage(message.search.trimmingSpaceAndNewLines)
                        }
                        Haptic.impact()
                    }label: {

                        HStack{
                            Image(systemName: messageShowMode == .abstract ? "eye.slash" : "doc.text.magnifyingglass")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                            Text(messageShowMode == .abstract ?  "隐藏"  : "总结")
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background26(.background, radius: 0)
            .background(BackgroundClearView())
            .animation(.spring(), value: messageShowMode)
            .onAppear{ self.hideKeyboard() }
            .onDisappear{ chatManager.cancellableRequest?.cancelRequest() }
            .sheet(isPresented: $showAssistantSetting) {
                NavigationStack{
                    AssistantSettingsView()
                }
            }
            .ignoresSafeArea()

    }


    
    private func translateMessage() {
        self.cancels?.cancelRequest()
        
        guard translateResult.isEmpty else { return }

        var datas: String = ""

        if let title = message.title, !title.isEmpty {
            datas += "\(title) <br>"
        }

        if let subtitle = message.subtitle, !subtitle.isEmpty {
            datas += "\(subtitle) <br>"
        }

        if let body = message.body, !body.isEmpty {
            datas += "\(body)"
        }
   
        guard assistantAccouns.first(where: {$0.current}) != nil else {
            Toast.error(title: "需要配置大模型")
            translateResult = String(localized: "❗️需要配置大模型")
            
            return
        }
    
        self.cancels = chatManager.chatsStream(text: datas, tips: .translate(translateLang.name)) { partialResult in
            switch partialResult {
            case .success(let result):
                
                if let res = result.choices.first?.delta.content {
                    DispatchQueue.main.async{
                        self.translateResult += res
                        Haptic.selection(limitFrequency: true)
                    }
                }
            case .failure(let error):
                //Handle chunk error here
                NLog.error(error)
                Toast.error(title: "发生错误\(error.localizedDescription)")
            }
            
            
        }completion: { err in
            if err != nil{
                DispatchQueue.main.async{
                    translateResult = ""
                }
            }
        }
        
    }
    
    
    
    private func abstractMessage(_ text: String) {
        self.cancels?.cancelRequest()
        guard abstractResult.isEmpty else { return }
   
        guard assistantAccouns.first(where: {$0.current}) != nil else {
            Toast.error(title: "需要配置大模型")
            abstractResult = String(localized: "❗️需要配置大模型")
            return
        }
    
        self.cancels = chatManager.chatsStream(text: text, tips: .abstract(translateLang.name)) { partialResult in
            switch partialResult {
            case .success(let result):
                
                if let res = result.choices.first?.delta.content {
                    DispatchQueue.main.async{
                        abstractResult += res
                        Haptic.selection(limitFrequency: true)
                    }
                }
            case .failure(let error):
                //Handle chunk error here
                NLog.error(error)
                Toast.error(title: "发生错误\(error.localizedDescription)")
            }
            
            
        }completion: { err in
            if err != nil{
                DispatchQueue.main.async{
                    abstractResult = ""
                }
            }
        }
        
    }
    
}


