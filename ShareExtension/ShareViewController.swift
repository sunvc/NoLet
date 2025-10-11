//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import Social
import SwiftUI
import UniformTypeIdentifiers
import CloudKit

class ShareViewController: UIViewController  {
    
    
    override func viewDidLoad() {
        if let itemProviders = (extensionContext!.inputItems.first as? NSExtensionItem)?.attachments {
            let hostingView = UIHostingController(rootView: ShareView(itemProviders: itemProviders, extensionContext: extensionContext, view: view, openHostApp: openURL))
            hostingView.view.frame = view.frame
            
            view.addSubview(hostingView.view)
        }
    }
    

    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = responder?.next
        }
        return false
    }
    
}

fileprivate struct ShareView: View {
    var itemProviders: [NSItemProvider]
    var extensionContext: NSExtensionContext?
    var view:UIView?
    var openHostApp:(URL)-> Bool
    
   
    @State private var pushIcon:PushIcon?


    
    var body: some View {
        VStack{
            Text("iCloud 云图标")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button("取消", action: dismiss)
                        .tint(.red)
                }
                .padding()
            
            if let pushIcon{
                UploadIclondIcon(pushIcon: pushIcon) { _ in
                    _ = openHostApp(PBScheme.pb.scheme(host: .openPage, params: ["page" : "icon"]))
                    dismiss()
                } endEditing: {
                    self.view?.endEditing(true)
                }
            }
            

        }
        .onAppear{
            extractItems()
        }
        
        
    }
    
    
    func extractItems() {
        guard pushIcon == nil else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            for provider in itemProviders {
                
                _ = provider.loadDataRepresentation(for: .data) { data, error in
                    guard let data = data else { return }
                    
                    if let image = data.toThumbnail(max: 300){
                        let tempDir = FileManager.default.temporaryDirectory
                        let tempURL = tempDir.appendingPathComponent("cloudIcon.png")
                        
                        guard let pngData = image.pngData() else { return }
                        
                        do{
                            try pngData.write(to: tempURL)
                        }catch{
                            NLog.error(error.localizedDescription)
                            return
                        }
                        
                         DispatchQueue.main.async {
                            
                            self.pushIcon = .init(id: UUID().uuidString, name: "", description: [], size: pngData.count, sha256: pngData.sha256(), file: tempURL, previewImage: image)
                        }
                    }
                    
                }
            }
        }
    }
    
    /// Dismissing View
    func dismiss() {
        extensionContext?.completeRequest(returningItems: [])
    }
    
}
