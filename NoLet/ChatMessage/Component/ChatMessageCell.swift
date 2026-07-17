//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - ChatMessageCell.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/15 09:13.
    
import SwiftUI
import MessagingUI


struct ChatMessageCell: TiledCellContent {
    typealias StateValue = Void

    let item: ChatMessage

    private let maxRevealOffset: CGFloat = 60

    private static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var quote: Message? {
        guard let messageID = AppManager.shared.askMessageID else { return nil }
        return MessagesManager.shared.query(id: messageID)
    }

    func body(context: CellContext<Void>) -> some View {
        let revealOffset = context.cellReveal?.rubberbandedOffset(max: maxRevealOffset) ?? 0
        let isUserMessage = item.role == ChatMessage.Role.user.rawValue

        VStack{
            if quote != nil {
                VStack {
                    if let quote = quote {
                        HStack {
                            Spacer()
                            QuoteView(message: quote.search)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }

            if !isUserMessage {
                ReasonButton(message: item)
            }

            if !item.content.removingAllWhitespace.isEmpty {
                HStack {
                    if isUserMessage {
                        Spacer()
                    }
                    
                    ScrollView {
                        MarkdownCustomView(content: item.content)
                            .padding()
                            .foregroundColor(.primary)
                    }
                    .frame(maxHeight: 400)
                    .if(isUserMessage) {
                        $0.background(Color.blue.opacity(0.2))
                    }
                    .if(!isUserMessage) {
                        $0.background26(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onTapGesture(count: 2) {
                        Clipboard.set(item.content)
                        Toast.success(title: "复制成功")
                    }
                    
                    if !isUserMessage {
                        Spacer()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
        }
        .offset(x: -revealOffset)
        .overlay(alignment: .trailing) {
            // Timestamp hidden off-screen, revealed on swipe
            Text(Self.timeFormatter.string(from: item.timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: maxRevealOffset)
                .offset(x: maxRevealOffset - revealOffset)
        }
        .clipped()
        .padding(.horizontal, 3)
        .padding(.vertical, 8)
    }
}
