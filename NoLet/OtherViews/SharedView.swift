//
//  SharedView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/10/12.
//

import LinkPresentation
import SwiftUI
import UIKit

class ActivityMetadataSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let title: String

    init(image: UIImage?, title: String) {
        self.image = image ?? UIImage(named: "logo")!
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ vc: UIActivityViewController) -> Any { return "" }
    func activityViewController(
        _ vc: UIActivityViewController,
        itemForActivityType type: UIActivity.ActivityType?
    ) -> Any? { return nil }

    func activityViewControllerLinkMetadata(_ vc: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}

// MARK: - UIActivityViewController 包装

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let preview: UIImage?
    let title: String?
    func makeUIViewController(context _: Context) -> UIActivityViewController {
        var finalItems = activityItems
        let metadataSource = ActivityMetadataSource(
            image: preview,
            title: title ?? String(localized: "分享内容")
        )
        finalItems.insert(metadataSource, at: 0)

        let controller = UIActivityViewController(
            activityItems: finalItems,
            applicationActivities: WeChatManager.SendType.allCases.map { item in
                MyCustomActivity(item, datas: finalItems)
            }
        )

        // iPad popover 支持
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        {
            if let popover = controller.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
        }

        // 分享完成回调
        controller.completionWithItemsHandler = { _, _, _, _ in
            for item in activityItems {
                if let content = item as? URL {
                    try? FileManager.default.removeItem(at: content)
                }
            }
        }

        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

nonisolated class MyCustomActivity: UIActivity {
    let type: WeChatManager.SendType
    let data: Any?

    init(_ type: WeChatManager.SendType, datas: [Any]) {
        self.type = type
        if datas.count > 1{
            self.data = datas[1]
        }else{
            self.data = nil
        }
    }

    override var activityTitle: String? { type.name }
    override var activityImage: UIImage? { UIImage(named: "wechat") }

    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("com.wzs.app.\(type.symbol)")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        return !ProcessInfo.processInfo.isiOSAppOnMac && WeChatManager.isWXAppInstalled()
    }


    override func perform() {
       
        if let image = self.data as? UIImage, let data = image.pngData() {

            WeChatManager.sendPng(data, type: self.type)
        }
        
        if let text = self.data as? String {
  
            WeChatManager.sendMessage(text, type: self.type)
        }
        
        activityDidFinish(true)
        
    }
}



