//
//  MessageCard.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/2/13.
//

import AVFAudio
import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct MessageCard: View {
    var message: Message
    var searchText: String = ""
    var showGroup: Bool = false
    var showAllTTL: Bool = false
    var showAvatar: Bool = true
    var complete: () -> Void
    var delete: () -> Void
    
    @State private var showLoading: Bool = false
    
    @State private var timeMode: Int = 0
    @Default(.limitMessageLine) var limitMessageLine
    @Default(.assistantAccouns) var assistantAccouns
    
    var dateTime: String {
        if showAllTTL {
            message.expiredTime()
        } else {
            switch timeMode {
            case 1: message.createDate.formatString()
            case 2: message.expiredTime()
            default: message.createDate.agoFormatString()
            }
        }
    }
    
    var linColor: Color {
        guard let selectID = AppManager.shared.selectID else {
            return .clear
        }
        return selectID.uppercased() == message.id.uppercased() ? .orange : .clear
    }
    
    @State private var showDetail: Bool = false
    @Namespace private var sms
    var body: some View {
        Section {
           
            VStack {
                HStack(alignment: .center) {
                    if showAvatar {
                        AvatarView(icon: message.icon)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.bottom, 5)
                            .overlay(alignment: .bottomTrailing) {
                                if message.level > 2 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .red)
                                }
                            }
                    }
                    VStack {
                        if let title = message.title {
                            MarkdownCustomView.highlightedText(searchText: searchText, text: title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        
                        if let subtitle = message.subtitle {
                            MarkdownCustomView.highlightedText(
                                searchText: searchText,
                                text: subtitle
                            )
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                
                if let urlstr = message.url {
                    HStack{
                        HStack(spacing: 1) {
                            Image(systemName: "network")
                                .imageScale(.small)
                            

                            MarkdownCustomView.highlightedText(
                                searchText: searchText,
                                text: urlstr
                            )
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .foregroundStyle(.accent)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        Spacer(minLength: 0)
                        
                        Image(systemName: "chevron.right")
                            .imageScale(.medium)
                            .foregroundStyle(.gray)
                    }
                    .onTapGesture {
                        if let url = message.url, let fileURL = URL(string: url) {
                            AppManager.openURL(url: fileURL, .safari)
                        }
                        Haptic.impact()
                    }
                }
                
                
                
                if message.title != nil || message.subtitle != nil || message
                    .url != nil || showAvatar{
                    Line()
                        .stroke(
                            .gray,
                            style: StrokeStyle(
                                lineWidth: 1,
                                lineCap: .butt,
                                lineJoin: .miter,
                                dash: [5, 3]
                            )
                        )
                        .frame(height: 1)
                        .padding(.vertical, 1)
                        .padding(.horizontal, 3)
                }
                VStack {
                    if let url = message.image {
                        
                        AsyncPhotoView(url: url, zoom: false, height: 230)
                            .padding( 5)
                            .diff { view in
                                Group {
                                    if #available(iOS 18.0, *) {
                                        view.onTapGesture {
                                            self.showDetail.toggle()
                                            Haptic.impact()
                                        }
                                    } else {
                                        view
                                            .VButton { _ in
                                                self.complete()
                                                return true
                                            }
                                    }
                                }
                            }
                        
                    }
                    
                    if let body = message.body, !body.isEmpty {
                        ScrollView(.vertical) {
                            MarkdownCustomView(content: body, searchText: searchText)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 5)
                                .onTapGesture(count: 2) {
                                    showFull()
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityValue(
                                    String("\(PBMarkdown.plain(message.accessibilityValue()))")
                                )
                                .accessibilityLabel("消息内容")
                                .accessibilityHint("双击全屏显示")
                                .accessibilityAction(named: "显示全屏") {
                                    showFull()
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .scrollDisabled(true)
                        .frame(maxHeight: CGFloat(limitMessageLine) * 30)
                        .clipShape(Rectangle())
                        
                    }
                }
            }
            .padding(8)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Haptic.impact()
                    showFull()
                } label: {
                    Label("全屏查看", systemImage: "arrow.up.backward.and.arrow.down.forward")
                        .symbolEffect(.rotate, delay: 2)
                }.tint(.orange)
                
               
            }
            .swipeActions(edge: .trailing) {
                Button {
                    self.delete()
                } label: {
                    Label("删除", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.primary)
                    
                }.tint(.red)
            }
            .overlay(alignment: .bottom) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 15,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 5,
                    topTrailingRadius: 15,
                    style: .continuous
                )
                .fill(.gray.opacity(0.6))
                .frame(height: 3)
                .padding(.horizontal, 30)
            }
            .frame(minHeight: 50)
            .mbackground26(.message, radius: 15)
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            .diff { view in
                Group {
                    if #available(iOS 18.0, *) {
                        view
                            .matchedTransitionSource(id: message.id, in: sms)
                            .fullScreenCover(isPresented: $showDetail) {
                                VStack {
                                    
                                    SelectMessageView(message: message) {
                                        self.showDetail = false
                                    }
                                    
                                }
                                .navigationTransition(
                                    .zoom(sourceID: message.id, in: sms)
                                )
                            }
                    } else {
                        view
                    }
                }
            }
            
        } header: {
            MessageViewHeader()
        }
    }
    
    func showFull() {
        if #available(iOS 18.0, *) {
            self.showDetail.toggle()
        } else {
            complete()
        }
        
        Haptic.impact(.light)
    }
    
    @ViewBuilder
    func MessageViewHeader() -> some View {
        HStack {
            Text(dateTime)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(AppManager.shared.selectID?.uppercased() == message.id
                    .uppercased() ?
                    .white : message.createDate.colorForDate())
                .padding(.leading, 10)
                .VButton(onRelease: { _ in
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
            
            if showGroup {
                MarkdownCustomView.highlightedText(searchText: searchText, text: message.group)
                    .textSelection(.enabled)
                    .accessibilityLabel("群组名")
                    .accessibilityValue(message.group)
                Spacer()
            }
            Menu{
                Section{
                    
                    Button {
                        Haptic.impact()
                        Clipboard.set(message.body)
                        Toast.copy(title: "复制成功")
                    } label: {
                        Label("复制", systemImage: "doc.on.clipboard")
                            .symbolEffect(.bounce, delay: 2)
                            .customForegroundStyle(.yellow, .white)
                        
                    }.tint(.accent)
                }
                
                
                if let url = message.url{
                    Button{
                        if let fileURL = URL(string: url) {
                            AppManager.openURL(url: fileURL, .safari)
                        }
                        Haptic.impact()
                    }label:{
                        Label(
                            "打开链接",
                            systemImage: "network"
                        )
                    }
                }
                
                if let image = message.image{
                    Section{
                        Button {
                            
                            Task{ 
                                if let file = await ImageManager.downloadImage( image),
                                   let uiimage = UIImage(contentsOfFile: file){
                                    uiimage.bat_save(intoAlbum: nil) { success, status in
                                        if status == .authorized || status == .limited {
                                            if success {
                                                Toast.success(title: "保存成功")
                                            } else {
                                                Toast.question(title: "保存失败")
                                            }
                                        } else {
                                            Toast.error(title: "没有相册权限")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label(
                                "保存图片",
                                systemImage: "square.and.arrow.down.on.square"
                            )
                        }
                    }
                }
                
                if assistantAccouns.count > 0 {
                    Section{
                        Button {
                            Haptic.impact()
                            DispatchQueue.main.async {
                                AppManager.shared.askMessageID = message.id
                                
                                if AppManager.shared.page == .message {
                                    AppManager.shared.router.append(.assistant)
                                } else if AppManager.shared.page == .search {
                                    AppManager.shared.router.append(.assistant)
                                }
                            }
                        } label: {
                            Label("智能助手", systemImage: "atom")
                                .symbolEffect(.rotate, delay: 2)
                        }.tint(.green)
                    }
                }
            }label: {
                HStack{
                    Spacer()
                    Image(systemName: "ellipsis")
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                }
                .contentShape(Rectangle())
            }.zIndex(9999)
        }
        .background(linColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(.horizontal, 15)
    }
}

#Preview {
    List {
        MessageCard(message: MessagesManager.examples().first!) {} delete: {}
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        
    }.listStyle(.grouped)
}

extension MessagesManager {
    static func examples() -> [Message] {
        [
            Message(
                id: UUID().uuidString,
                createDate: .now,
                group: "Markdown",
                title: String(localized: "示例"),
                body: "# NoLet \n## NoLet \n### NoLet",
                level: 1,
                ttl: 1,
                read: false
            ),
            
            Message(
                id: UUID().uuidString,
                createDate: .now,
                group: String(localized: "示例"),
                title: String(localized: "使用方法"),
                body: String(localized: """
                    * 右上角功能菜单，使用示例，分组
                    * 单击图片/双击消息全屏查看
                    * 全屏查看，翻译，总结，朗读
                    * 左滑删除，右滑复制和智能解答。
                    """),
                level: 1,
                ttl: 1,
                read: false
            ),
            
            Message(
                id: UUID().uuidString,
                createDate: .now,
                group: "App",
                title: String(localized: "点击跳转app"),
                body: String(localized: "url属性可以打开URLScheme, 点击通知消息自动跳转，前台收到消息自动跳转"),
                url: "weixin://",
                level: 1,
                ttl: 1,
                read: false
            ),
        ]
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        }
    }
}

extension View {
    @ViewBuilder
    func mbackground26<S>(_ color: S, radius: CGFloat = 0) -> some View where S: ShapeStyle {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
        } else {
            background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(color)
                    .shadow(group: false)
            )
        }
    }
    
    func shadow(group _: Bool) -> some View {
        shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .shadow(color: Color.shadow1, radius: 5, x: 3, y: 5)
    }
}

extension Message {
    fileprivate func accessibilityValue() -> String {
        var text: [String] = []
        
        text
            .append(
                String(localized: "时间:") + createDate
                    .formatted(date: .long, time: .standard)
            )
        
        if let title = title {
            text.append(String(localized: "标题") + ":" + title)
        }
        if let subtitle = subtitle {
            text.append(String(localized: "副标题") + ":" + subtitle)
        }
        
        if let body = body {
            text.append(String(localized: "内容") + ":" + body)
        }
        
        if image != nil {
            text.append(String(localized: "附件: 一张图片"))
        }
        
        if let url = url {
            text.append(String(localized: "跳转链接:") + url)
        }
        
        return text.joined(separator: "\n")
    }
    
    fileprivate func expiredTime() -> String {
        if ttl == ExpirationTime.forever.rawValue {
            return "∞ ∞ ∞"
        }
        
        let days = createDate.daysRemaining(afterSubtractingFrom: ttl)
        if days <= 0 {
            return String(localized: "已过期")
        }
        
        let calendar = Calendar.current
        let now = Date()
        let targetDate = calendar.date(byAdding: .day, value: days, to: now)!
        
        let components = calendar.dateComponents([.year, .month, .day], from: now, to: targetDate)
        
        if let years = components.year, years > 0 {
            return String(localized: "\(years)年")
        } else if let months = components.month, months > 0 {
            return String(localized: "\(months)个月")
        } else if let days = components.day {
            return String(localized: "\(days)天")
        }
        
        return String(localized: "即将过期")
    }
}

