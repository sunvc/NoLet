//
//  MarkdownCustomView.swift
//  pushback
//
//  Created by lynn on 2025/3/26.
//

import SwiftUI
import MarkdownUI
import Splash
import Kingfisher
import cmark_gfm
import cmark_gfm_extensions
import Foundation
import WebKit


struct MarkdownCustomView:View {
    @Environment(\.colorScheme) var colorScheme
    
    var content:String
    var searchText:String
    var scaleFactor: CGFloat
    
    private var codeHighlightColorScheme: Splash.Theme {
        colorScheme == .dark ? .wwdc17(withFont: .init(size: 16)) : .sunset(withFont: .init(size: 16))
    }
    
    init( content: String, searchText: String = "", scaleFactor: CGFloat = 1.0) {
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText = searchText
        self.scaleFactor = scaleFactor
    }
    
    @ScaledMetric(relativeTo: .callout) var baseSize: CGFloat = 17
    
    var body: some View {
        
        if  !searchText.isEmpty{
            
            MarkdownCustomView.highlightedText(searchText: searchText, text:  PBMarkdown.plain(content))
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
        }else {
            
            Markdown(content)
                .markdownImageProvider(WebImageProvider())
                .environment(\.openURL, OpenURLAction { url in
                    AppManager.openUrl(url: url)
                    return .handled // 表示链接已经被处理，不再执行默认行为
                })
                .markdownCodeSyntaxHighlighter(.splash(theme: codeHighlightColorScheme))
                .markdownTheme(MarkdownTheme.defaultTheme(baseSize, scaleFactor: scaleFactor))
                
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                
        }
        
    }
    
    
    static func highlightedText(searchText: String, text: String) -> Text {
        // 拆分关键词 & 小写比较用
        let keywords = searchText
            .lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
        
        // 没有关键词，直接返回原文
        guard !keywords.isEmpty else {
            return Text(text)
        }
        
        // 创建匹配范围集合
        let lowercasedText = text.lowercased()
        var ranges: [Range<String.Index>] = []
        
        for keyword in keywords {
            var searchStart = lowercasedText.startIndex
            while let range = lowercasedText.range(of: keyword, range: searchStart..<lowercasedText.endIndex) {
                ranges.append(range)
                searchStart = range.upperBound
            }
        }
        
        // 合并重叠区间
        let mergedRanges = mergeRanges(ranges.sorted { $0.lowerBound < $1.lowerBound })
        
        // 构造高亮 Text
        var result = Text(verbatim: "")
        var currentIndex = text.startIndex
        
        for range in mergedRanges {
            // 非匹配部分
            if currentIndex < range.lowerBound {
                result = result + Text(String(text[currentIndex..<range.lowerBound]))
            }
            // 匹配部分高亮
            result = result + Text(String(text[range])).bold().foregroundColor(.red)
            currentIndex = range.upperBound
        }
        
        // 剩下尾部
        if currentIndex < text.endIndex {
            result = result + Text(String(text[currentIndex..<text.endIndex]))
        }
        
        return result
    }
    
    private static func mergeRanges(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        guard !ranges.isEmpty else { return [] }
        
        var merged: [Range<String.Index>] = []
        var current = ranges[0]
        
        for next in ranges.dropFirst() {
            if current.upperBound >= next.lowerBound {
                // 合并重叠
                current = current.lowerBound..<max(current.upperBound, next.upperBound)
            } else {
                merged.append(current)
                current = next
            }
        }
        
        merged.append(current)
        return merged
    }
    
    
}


struct WebImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        WebImageView(url: url)
    }
}


enum ImagePhase : Sendable {
    case empty
    case success(UIImage)
    case failure(String)
}


struct WebImageView: View {
    var url: URL?
    @State private var image:UIImage?
    @State private var status:ImagePhase = .empty
    var body: some View {
        switch status {
        case .empty:
            Label("正在处理中...", systemImage: "rays")
                .task{
                    Task.detached(priority: .background) {
                        await self.loadImage(url: url)
                    }
                }
        case .success(let image):
           
            ResizeToFit(idealSize: image.size) {
                Menu {
                    Button {
                        
                        image.bat_save(intoAlbum: nil) { success, status in
                            if status == .authorized || status == .limited{
                                if success{
                                    Toast.success(title: "保存成功")
                                }else{
                                    Toast.question(title: "保存失败")
                                }
                            }else{
                                Toast.error(title: "没有相册权限")
                            }
                            
                        }
                        Haptic.impact(.light)
                    } label: {
                        Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, .primary)
                    }
                } label: {
                    Image(uiImage: image)
                        .resizable()
                }
            }
            
        case .failure(let error):
            Text(verbatim: error)
        @unknown default:
            Text("图片未加载")
        }
        
    }
    func loadImage(url:URL?) async {
        if let url = url{
            if  let imageUrl = await ImageManager.downloadImage(url.absoluteString),
            let uiImage = UIImage(contentsOfFile: imageUrl)
            {
                self.image = uiImage
                self.status = .success(uiImage)
            }else{
                self.status = .failure(String(localized: "加载失败"))
            }
        }else{
            self.status = .failure(String(localized: "地址错误"))
        }
        
    }
    
}
