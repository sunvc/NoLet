//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChatView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/22 09:13.

import SwiftUI

struct ChatList: UIViewRepresentable {
    let isScrollEnabled: Bool
    let keyboardDismissMode: UIScrollView.KeyboardDismissMode
    let datas: [ChatMessage]

    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)

        // 核心配置 A：彻底禁用安全区域对内边距的干预
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.insetsLayoutMarginsFromSafeArea = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.transform = CGAffineTransform(rotationAngle: .pi)

        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedSectionHeaderHeight = 1
        tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.scrollsToTop = false
        tableView.isScrollEnabled = isScrollEnabled
        tableView.keyboardDismissMode = keyboardDismissMode
        NotificationCenter.default
            .addObserver(forName: .onScrollToBottom, object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
//                if !context.coordinator.sections.isEmpty {
//                    guard tableView.numberOfSections > 0, tableView.numberOfRows(inSection: 0) > 0
//                    else { return }
//                    tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
//                }
                }
            }

        return tableView
    }

    func updateUIView(_ tableView: UITableView, context: Context) {
        // 只有当数据真的不一致时才刷新，避免循环触发
        if context.coordinator.datas != datas {
            context.coordinator.datas = datas
            tableView.reloadData()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(datas: datas)
    }

    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
        var datas: [ChatMessage]
        init(datas: [ChatMessage]) {
            self.datas = datas
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return datas.count
        }

        func tableView(
            _ tableView: UITableView,
            cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {
            let tableViewCell = tableView.dequeueReusableCell(
                withIdentifier: "Cell",
                for: indexPath
            )
            tableViewCell.selectionStyle = .none
            tableViewCell.backgroundColor = UIColor(.clear)
            let message = datas[indexPath.row]
            tableViewCell.contentConfiguration = UIHostingConfiguration {
                ChatMessageView(message: message)
                    .rotationEffect(Angle(degrees: 180))
            }
            .minSize(width: 0, height: 0)
            .margins(.vertical, 100)
            return tableViewCell
        }
    }
}

extension Notification.Name {
    public static let onScrollToBottom = Notification.Name("onScrollToBottom")
}

@available(iOS 17.0, *)
#Preview {
    NavigationStack { 
        ChatList(isScrollEnabled: true, keyboardDismissMode: .interactive, datas: [
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
            ChatMessage(timestamp: .now, chat: "", request: "123", content: "123"),
        ])
        .ignoresSafeArea()
        .toolbar { 
            ToolbarItem(placement: .topBarLeading) { 
                Text("123")
            }
        }
    }
    
}
