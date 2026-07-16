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

        VStack{
            if item.request.count > 0 || quote != nil {
                VStack {
                    if let quote = quote {
                        HStack {
                            Spacer()
                            QuoteView(message: quote.search)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                    }
                    
                    
                    if item.request.count > 0 {
                        HStack {
                            Spacer()

                            MarkdownCustomView(content: item.request)
                                .padding()
                                .foregroundColor(.primary)
                                .background(Color.blue.opacity(0.2))
                                .onTapGesture(count: 2) {
                                    Clipboard.set(item.request)
                                    Toast.success(title: "复制成功")
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }

            ReasonButton(message: item)

            if !item.content.removingAllWhitespace.isEmpty {
                HStack {
                    MarkdownCustomView(content: item.content)
                        .padding()
                        .foregroundColor(.primary)
                        .background26(.ultraThinMaterial)
                        .foregroundColor(.primary)
                        .lineLimit(8)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .onTapGesture(count: 2) {
                            Clipboard.set(item.content)
                            Toast.success(title: "复制成功")
                        }
                    Spacer()
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
