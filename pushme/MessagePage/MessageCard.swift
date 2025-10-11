//
//  MessageCardView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults
import AVFAudio
import UniformTypeIdentifiers

struct MessageCard: View {
    
    var message:Message
    var searchText:String = ""
    var showGroup:Bool =  false
    var showAllTTL:Bool = false
    var showAvatar:Bool = true
    var complete:()->Void
    var delete:()->Void

    @State private var showLoading:Bool = false
    
    @State private var timeMode:Int = 0
    @Default(.limitMessageLine) var limitMessageLine
    
    var dateTime:String{
        if showAllTTL{
            message.expiredTime()
        }else{
            switch timeMode {
            case 1: message.createDate.formatString()
            case 2: message.expiredTime()
            default: message.createDate.agoFormatString()
            }
        }
    }
    
    
    var linColor:Color{
        guard let selectId = AppManager.shared.selectId else {
            return .clear
        }
        return selectId.uppercased() == message.id.uppercased() ? .orange : .clear
        
    }
    @State private var image:UIImage? = nil
    @State private var imageHeight:CGFloat = .zero
    @State private var showDetail:Bool = false
    @Namespace private var sms
    var body: some View {
        Section {
            VStack{
                HStack(alignment: .center){
                    if showAvatar{
                        
                        AvatarView( icon: message.icon)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.bottom, 5)
                            .overlay(alignment: .bottomTrailing) {
                                if message.level > 2{
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .red)
                                }
                            }
                        
                    }
                    VStack{
                        if let title = message.title{
                            MarkdownCustomView.highlightedText(searchText: searchText, text: title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        
                        if let subtitle = message.subtitle{
                            MarkdownCustomView.highlightedText(searchText: searchText, text: subtitle)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let url =  message.url{
                            HStack(spacing: 1){
                                Image(systemName: "network")
                                    .imageScale(.small)
                                    
                                MarkdownCustomView.highlightedText(searchText: searchText, text: url)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundStyle(.accent)
                        }
                    }
                    Spacer(minLength: 0)
                    if message.url != nil {
                        Image(systemName: "chevron.right")
                            .imageScale(.medium)
                            .foregroundStyle(.gray)
                    }
                }
                .contentShape(Rectangle())
                .if(message.url != nil){ view in
                    Group{
                        if #available(iOS 26.0, *){
                            view
                                .onTapGesture {
                                    if let url = message.url, let fileUrl = URL(string: url){
                                        AppManager.openUrl(url: fileUrl)

                                    }
                                    Haptic.impact()
                                }
                        }else{
                            view
                                .VButton{ _ in
                                    if let url = message.url, let fileUrl = URL(string: url){
                                        AppManager.openUrl(url: fileUrl)

                                    }
                                    return true
                                }
                        }
                    }

                }
                
                
                if message.title != nil || message.subtitle != nil || message.url != nil || showAvatar{
                    Line()
                        .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5,3]))
                        .frame(height: 1)
                        .padding(.vertical,1)
                        .padding(.horizontal, 3)
                    
                }
                VStack{
                    if let uiImage = image{
                        GeometryReader { proxy in
                            
                            VStack{
                                
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                                    .onAppear{
                                        let size = uiImage.size
                                        let aspectRatio = size.height / size.width
                                        imageHeight = proxy.size.width * aspectRatio
                                    }
                                    .contextMenu{
                                        Button{
                                            if let image = image{
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
                                            }
                                        }label:{
                                            Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                                        }
                                    }preview: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                                    }
                                
                               
                                
                                Line()
                                    .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5,3]))
                                    .frame(height: 1)
                                    .padding(.vertical,1)
                                    .padding(.horizontal, 3)
                            }
                        }
                        .frame(height: imageHeight)
                        .clipShape(Rectangle())
                        .contentShape(Rectangle())
                        .diff{ view in
                            Group{
                                if #available(iOS 18.0, *){
                                    view.onTapGesture {
                                            self.showDetail.toggle()
                                            Haptic.impact()
                                        }
                                }else{
                                    view
                                        .VButton{ _ in
                                            self.complete()
                                            
                                            return true
                                        }
                                }
                            }
                        }

                    }
                    
                    if let body = message.body{
                        MarkdownCustomView(content: body, searchText: searchText)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 5)
                            .lineLimit(limitMessageLine)
                            .onTapGesture(count: 2) {
                                showFull()
                            }
                        
                            .accessibilityElement(children: .ignore)
                            .accessibilityValue("\(PBMarkdown.plain(message.accessibilityValue()))")
                            .accessibilityLabel("消息内容`")
                            .accessibilityHint("双击全屏显示")
                            .accessibilityAction(named: "显示全屏") {
                                showFull()
                            }
                    }
                }
                
               
            }
            .padding(8)

            .swipeActions(edge: .leading , allowsFullSwipe: true){
                Button{
                    Haptic.impact()
                    DispatchQueue.main.async{

                        AppManager.shared.askMessageId = message.id

                        if AppManager.shared.page == .message{
                            AppManager.shared.router.append(.assistant)
                        }else if AppManager.shared.page == .search{
                            AppManager.shared.router.append(.assistant)
                        }
                    }
                }label:{
                    Label("智能助手", systemImage: "atom")
                        .symbolEffect(.rotate, delay: 2)
                }.tint(.green)

                Button{
                    Haptic.impact()
                    if let image = image {
                        Clipboard.set(message.search,[UTType.image.identifier: image])
                    }else{
                        Clipboard.set(message.search)
                    }
                    Toast.copy(title: "复制成功")
                }label:{
                    Label("复制", systemImage: "doc.on.clipboard")
                        .symbolEffect(.bounce, delay: 2)
                        .customForegroundStyle(.yellow, .white)

                }.tint(.accent)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    self.delete()
                } label: {
                    
                    Label( "删除", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.primary)
                    
                }.tint(.red)
            }
            .overlay(alignment: .bottom) {
                UnevenRoundedRectangle(topLeadingRadius: 15, bottomLeadingRadius: 5, bottomTrailingRadius: 5, topTrailingRadius: 15,style: .continuous)
                    .fill(.gray.opacity(0.6))
                    .frame(height: 3)
                    .padding(.horizontal, 30)
            }
            .frame(minHeight: 50)
            .mbackground26(.message, radius: 15)
            .onAppear{
                if self.image == nil{
                    Task(priority: .background) {
                        if let image = message.image,
                           let file = await ImageManager.downloadImage(image){
                            self.image = UIImage(contentsOfFile: file)
                            
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            .diff{ view in
                Group{
                    if #available(iOS 18.0, *){
                        view
                            .matchedTransitionSource(id: message.id, in: sms)
                            .fullScreenCover( isPresented: $showDetail){
                                VStack{
                                    NavigationStack{
                                        SelectMessageView(message: message) {
                                            self.showDetail = false
                                        }
                                    }
                                }
                                .navigationTransition(
                                    .zoom(sourceID: message.id, in: sms)
                                )

                            }
                    }else{
                        view
                    }
                }
            }


        }header: {
            MessageViewHeader()

        }
        
    }

    func showFull(){
        if #available(iOS 18.0, *){
            self.showDetail.toggle()
        }else{
            self.complete()
        }

        Haptic.impact(.light)
    }

    @ViewBuilder
    func MessageViewHeader()-> some View{
        HStack{
            
            Text(dateTime)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(AppManager.shared.selectId?.uppercased() == message.id.uppercased() ?
                    .white : message.createDate.colorForDate() )
                .padding(.leading, 10)
                .VButton(onRelease: { value in
                    withAnimation {
                        let number = self.timeMode + 1
                        self.timeMode = number > 2 ? 0 : number
                    }
                    return true
                })
                .accessibilityLabel("时间:")
                .accessibilityValue(message.createDate
                    .formatted(date: .long, time: .standard))

            Spacer()

            if showGroup{
                MarkdownCustomView.highlightedText(searchText: searchText, text: message.group)
                    .textSelection(.enabled)
                    .accessibilityLabel("群组名")
                    .accessibilityValue( message.group)
            }
            
        }
        .background(linColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(.horizontal, 15)
    }
    
    
    
    func limitTextToLines(_ text: String, charactersPerLine: Int) -> String {
        var result = ""
        var currentLineCount = 0
        
        for char in text {
            result.append(char)
            if char.isNewline || currentLineCount == charactersPerLine {
                result.append("\n")
                currentLineCount = 0
            } else {
                currentLineCount += 1
            }
        }
        
        return result
    }
    
}


#Preview {
    
    List {
        MessageCard(message: MessagesManager.examples().first!){

        }delete:{

        }
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets())

    }.listStyle(.grouped)
    
    
}


struct Line: Shape{
    func path(in rect: CGRect) -> Path {
        return Path{path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            
        }
    }
    
}



extension View{
    @ViewBuilder
    func mbackground26<S>(_ color: S, radius: CGFloat = 0) -> some View where S : ShapeStyle{
        if #available(iOS 26.0, *){
            self
                .glassEffect(.regular.interactive(),in: .rect(cornerRadius: radius))
        }else{
            self
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(color)
                        .shadow(group: false)
                )
        }
    }

    func shadow(group: Bool) -> some View {
        self
            .shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .shadow(color: Color.shadow1, radius: 5, x: 3, y: 5)
    }
}
