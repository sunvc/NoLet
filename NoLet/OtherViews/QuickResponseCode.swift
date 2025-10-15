//
//  QuickResponseCode.swift
//  pushback
//
//  Created by lynn on 2025/5/4.
//

import SwiftUI

struct QuickResponseCodeview:View {
    @Environment(\.dismiss) var dismiss
    var image:Image?
    var text:String
    var title:String
    var shareTitle:String
    init(text:String, title:String? = nil, preview:String? = nil) {
        self.text = text
        if let title {
            self.title = title
        }else{
            self.title =  String(localized: "快速预览")
        }
        if let preview{
            self.shareTitle = preview
        }else{
            self.shareTitle = String(localized: "二维码")
        }
        
        
        if let image = generateQRCode(from: text){
            self.image = Image(uiImage: image)
        }
        
    }
    @State private var raw:Bool = false
    
    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    ZStack{
                    
                        if raw {
                            Text(text)
                                .textSelection(.enabled)
                                .font(.title3)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: 300)
                                .transition(.scale.combined(with: .opacity))
                                
                        }else{
                            if let image = image{
                                image
                                    .customDraggable(100)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    
                   
                    Spacer()
                }
                Spacer()
            }
            .animation(.default, value: raw)
            .contentShape(Rectangle())
            .onTapGesture(count: self.raw ? 1 : 2) {
                self.raw.toggle()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .VButton( onRelease: { _ in
                            self.dismiss()
                            return true
                        })
                        .accessibilityLabel("关闭")
                        .accessibilityAddTraits(.isButton)
                }
                
                ToolbarItem{
                    Image(systemName: !raw ? "eyeglasses" : "eyeglasses.slash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, .gray)
                        .fontWeight(.bold)
                        .symbolEffect(.replace)
                        .VButton(onRelease: { _ in
                            self.raw.toggle()
                            return true
                        })
                        .accessibilityLabel( "切换显示")
                        .accessibilityAddTraits(.isButton)

                }
                
                
                ToolbarItem {
                    if !raw, let image = image{
                        ShareLink(item: image, preview: SharePreview(shareTitle, image: image))
                    }else{
                        ShareLink("分享", item: text)
                    }
                }
            }
        }
    }
    
    func generateQRCode(from string: String, size: CGSize = .init(width: 300, height: 300)) -> UIImage? {
        // 创建二维码生成器
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        // 设置输入数据
        let data = string.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // 获取二维码图像
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        // 设置二维码图像的大小
        let transform = CGAffineTransform(scaleX: size.width / ciImage.extent.size.width, y: size.height / ciImage.extent.size.height)
        let scaledImage = ciImage.transformed(by: transform)
        
        // 转换为 UIImage
        let context = CIContext()
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
}
