//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ReasonMessageView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  Description:
//
//  History:
//    Created by Neo on 2026/1/7 09:01.
//
import SwiftUI

struct ReasonMessageView: View {
    @Binding var message: ChatMessage?
    var reasons: [String] {
        message?.reason?.split(separator: "\n").compactMap { String($0) } ?? []
    }

    var body: some View {
        VStack {
            ReasonButton(message: message, openShow: false) {
                self.message = nil
            }
            .padding(.vertical)
            .padding(.horizontal)
            .contentShape(Rectangle())

            ScrollView(.vertical) {
                
                
                
                VStack(spacing: 0) {
                    if let result = message?.result, let text = result.text(){
                        reasonView(
                        """
                        ```json
                        \(text)
                        ```
                        """
                        )
                    }
                    ForEach(reasons, id: \.self) { item in
                      reasonView(item)
                    }
                }
                .padding(.vertical)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
    
    @ViewBuilder
    func reasonView(_ item: String)-> some View{
        HStack(alignment: .top, spacing: 0) {
            // Left Track
            VStack(spacing: 0) {
                // Top Icon
                Circle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.2)

                // Vertical Line
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 4)

                if item == reasons.last {
                    // Top Icon
                    Circle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 24)
            .padding(.leading, 16)
            .padding(.trailing, 8)

            // Right Content
            VStack(alignment: .leading, spacing: 0) {
                MarkdownCustomView(content: item)
                    .padding(.vertical)
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)

                if item == reasons.last {
                    Text("完成")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct ReasonButton: View {
    var message: ChatMessage?
    var openShow: Bool = true
    var close: (() -> Void)? = nil
    @EnvironmentObject private var chatManager: NoLetChatManager

    var show: Bool {
        chatManager.startReason == message?.id
    }

    var showResult: Bool {
        if let result = message?.result, !result.isEmpty {
            return true
        }
        return false
    }
    
    var showReason: Bool {
        if let reason = message?.reason, !reason.isEmpty  {
            return true
        }
        return false
    }

    var body: some View {
        HStack {
            if showResult || showReason {
                Button {
                    if openShow {
                        chatManager.showReason = message
                    } else {
                        self.close?()
                    }
                } label: {
                    
                    HStack(alignment: .center, spacing: 5) {
                        
                        if !openShow {
                            Image(systemName: "chevron.left")
                        }
                        
                        if showReason{
                           
                            if show {
                                Spinner(tint: Color.orange, lineWidth: 3)
                                    .frame(width: 15, height: 15, alignment: .center)
                            }

                            Text(show ? "思考中" : "已思考")

                            if show {
                                Text("...")
                                    .frame(width: 18, alignment: .leading) // 防抖
                            }

                        }
                        
                        if showResult{
                            Text(verbatim: "MCP")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                            
                        }
                        
                        if openShow{
                            Image(systemName: "chevron.right")
                        }
                        
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                }
                .padding(.horizontal, 20)
            }
            Spacer()
        }
    }
}
