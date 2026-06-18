//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PlainMessageView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:20.

import SwiftUI

struct PlainMessageView: View {
    let message: Message
    var searchText: String = ""
    var assistantAccouns: Int
    var delete: () -> Void

    @ObservedObject var manager = AppManager.shared
    @Namespace private var messageNameSpace
    @State private var replyText: String = ""
    @FocusState private var showReply
    @State private var showSnap: Bool = false

    var selectIDColor: Color {
        guard let selectID = manager.selectID else {
            return .clear
        }
        return selectID.uppercased() == message.id.uppercased() ? .orange : .clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 顶部图片与标签区域
            if let image = message.image {
                AsyncPhotoView(url: image, zoom: false, height: 200)
                    .padding(5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.showFull()
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let url = message.url, let url = URL(string: url) {
                        Link("打开链接", destination: url)
                            .font(.footnote)
                            .tint(.blue)
                    }

                    Spacer()
                    Text(message.createDate, format: .relative(presentation: .named))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                if message.title != nil || message.subtitle != nil {
                    VStack(alignment: .leading, spacing: 2) {
                        // 主标题
                        if let title = message.title {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        if let subtitle = message.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .fontWeight(.heavy)
                                .foregroundColor(.secondary)
                                .tracking(1) // 字间距
                        }
                    }
                }

                SCSelectableTextRepresentable(
                    text: message.body.plainText,
                    font: .systemFont(ofSize: 17, weight: .medium),
                    textColor: .textBlack,
                    textAlignment: .left,
                    lineLimit: 5
                )

                Divider()
                    .padding(.top, 6)

                HStack {
                    AvatarView(icon: message.icon)
                        .frame(width: 30, height: 30, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack {
                        Text(message.group)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 5)
                    }

                    Spacer()

                    MessageActionMenu(
                        message: message,
                        assistantAccounsCount: assistantAccouns,
                        manager: manager,
                        showSnap: $showSnap,
                        showReply: $showReply,
                        onDelete: delete
                    )
                }
            }
            .padding(20)
        }
        .glassCard(24, padding: 10)
        .messageInteraction(
            message: message,
            in: messageNameSpace,
            manager: manager,
            replyText: $replyText,
            showReply: $showReply,
            showSnap: $showSnap,
            onShowFull: showFull
        )
        .shadow(color: selectIDColor, radius: 10, x: 0, y: 0)
    }

    func showFull() {
        manager.selectMessage = message

        Haptic.impact(.light)
    }
}

#Preview {
    PlainMessageView(message: Message(
        id: UUID().uuidString,
        createDate: .now.addingTimeInterval(-60000),
        group: "工作",
        title: "如何用正念重塑你与自然的关系",
        subtitle: "探索自然",
        body: "在这个快节奏的时代，沉浸于自然不仅是一种放松，更是一场心灵的治愈之旅。本文将带你探索那些被忽视的绿色角落。",
        url: "https://wzs.app",

        ttl: 1000,
        read: false
    ), assistantAccouns: 0) {}
}

final class SelectableTextView: UITextView {

    override func copy(_ sender: Any?) {
        super.copy(sender)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.selectedRange = NSRange(location: 0, length: 0)
            self.resignFirstResponder()
            Toast.copy()
        }
    }
    
    override func editMenu(
        for textRange: UITextRange,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {

        let deselectAction = UIAction(
            title: "取消",
            image: UIImage(systemName: "xmark")
        ) { [weak self] _ in
            self?.selectedTextRange = nil
        }
        
        var suggestedActions = suggestedActions
        
        suggestedActions.insert(deselectAction, at: 1)

        return UIMenu(children: suggestedActions)
    }
 
}

struct SCSelectableTextRepresentable: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let textAlignment: NSTextAlignment
    let lineLimit: Int?

    func makeUIView(context: Context) -> SelectableTextView {
        let textView = SelectableTextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: SelectableTextView, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.textColor = textColor
        uiView.textAlignment = textAlignment
        uiView.textContainer.maximumNumberOfLines = lineLimit ?? 0
        uiView.textContainer.lineBreakMode = lineLimit == nil ? .byWordWrapping : .byTruncatingTail
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: SelectableTextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else {
            return nil
        }

        let targetSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let fittedSize = uiView.sizeThatFits(targetSize)
        return CGSize(width: width, height: ceil(fittedSize.height))
    }
    
}
