//
//  Image+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//
import Photos
import PhotosUI
import SwiftUI

extension Image {
    @ViewBuilder
    func customDraggable(
        _ width: CGFloat = .zero,
        appear: ((Image) -> Void)? = nil,
        disappear: ((Image) -> Void)? = nil
    ) -> some View {
        draggable(self) {
            self
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width == .zero ? 300 : width)
                .onAppear {
                    appear?(self)
                }
                .onDisappear {
                    disappear?(self)
                }
        }
    }
    
    
}

extension View{
    /// 包装 UIKit 后的图片选择修饰符
    /// - Parameters:
    ///   - isPresented: 是否展现选择器
    ///   - onResult: 结果回调，成功返回 UIImage，失败返回 Error
    @ViewBuilder
    func imageImporter(
        isPresented: Binding<Bool>,
        onResult: @escaping (Result<UIImage, Error>) -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ImagePickerRepresentable(isPresented: isPresented, onResult: onResult)
                .ignoresSafeArea()
        }
    }
}

struct ImagePickerRepresentable: UIViewControllerRepresentable {
    // 控制弹窗的显示与隐藏
    @Binding var isPresented: Bool
    // 选择成功后的回调闭包
    var onResult: (Result<UIImage, Error>) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        // 配置 PHPicker
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // 只筛选图片
        configuration.selectionLimit = 1 // 单选（若需多选可调整）

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 协调器：处理 UIKit 的代理回调
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerRepresentable

        init(_ parent: ImagePickerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // 关闭弹窗
            parent.isPresented = false

            guard let provider = results.first?.itemProvider else {
                return
            }

            // 安全读取图片数据
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    if let error = error {
                        Task { @MainActor in
                            self?.parent.onResult(.failure(error))
                        }
                    } else if let uiImage = object as? UIImage {
                        // 切换回主线程返回结果
                        Task { @MainActor in
                            self?.parent.onResult(.success(uiImage))
                        }
                    }
                }
            } else {
                parent.onResult(.failure(NSError(
                    domain: "ImageImporter",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "无法加载该格式的图片"]
                )))
            }
        }
    }
}


nonisolated extension String{
    func avatarImage(size: CGFloat = 300, padding: CGFloat = 16) -> UIImage? {
        guard let textColor = (self.filter { !$0.isWhitespace }).decomposeTextAndColor() else { return nil }

        let singleEmoji = textColor.text.first?.isEmoji ?? false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let backgroundColor: UIColor = singleEmoji ? .clear : textColor.background

        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)

            // 可用绘图区域为去除 padding 后的部分
            let availableRect = rect.insetBy(dx: padding, dy: padding)

            let fontSize = availableRect.height * (singleEmoji ? 1 : 0.85)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: textColor.color,
            ]

            let textSize = textColor.text.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            )

            textColor.text.draw(at: textOrigin, withAttributes: attributes)
        }
    }
}


nonisolated extension String{
    func decomposeTextAndColor(
        _ defaultColor: UIColor = .white,
        _ backgroundColor: UIColor = .systemBlue
    )-> (text: String, color: UIColor, background: UIColor)?
    {
        // 拆分字符串，最多取 3 个
        let parts = split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let first = parts.first, !first.isEmpty else {
            return nil // 第一个为空，返回 nil
        }

        // 转成字符数组（注意 Character 可以表示 emoji）
        let chars = Array(first)
        var firstChar: String

        // 如果第一个是 emoji，直接只取一个
        if chars.first?.isEmoji == true {
            firstChar = String(chars[0])
        } else {
            if chars.count >= 2 {
                if chars[0].isLetter || chars[0].isNumber,
                   chars[1].isLetter || chars[1].isNumber
                {
                    firstChar = String(chars[0...1]) // 前两个都是字母/数字
                } else {
                    firstChar = String(chars[0]) // 否则只取第一个
                }
            } else {
                firstChar = String(chars[0])
            }
        }

        switch parts.count {
        case 1:
            return (firstChar, defaultColor, backgroundColor)
        case 2:
            return (firstChar, .white, UIColor(hexString: parts[1]) ?? backgroundColor)
        case 3...:
            return (
                firstChar,
                UIColor(hexString: parts[1]) ?? defaultColor,
                UIColor(hexString: parts[2]) ?? backgroundColor
            )
        default:
            return nil
        }
    }
}

