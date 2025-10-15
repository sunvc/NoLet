//
//  SharedView.swift
//  pushme
//
//  Created by Neo on 2025/10/12.
//

import SwiftUI
import UIKit

// MARK: - UIActivityViewController 包装
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]           // 分享内容
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: nil)
        
        // iPad popover 支持
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            
            if let popover = controller.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX,
                                            y: rootVC.view.bounds.midY,
                                            width: 0,
                                            height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        // 分享完成回调
        controller.completionWithItemsHandler = { _, _, _, _ in
            for item  in activityItems{
                if let content = item as? URL{
                    try? FileManager.default.removeItem(at: content)
                }
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
