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
    @Binding var isPresented: Bool
    var onResult: (Result<UIImage, Error>) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

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
            parent.isPresented = false

            guard let provider = results.first?.itemProvider else {
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    if let error = error {
                        Task { @MainActor in
                            self?.parent.onResult(.failure(error))
                        }
                    } else if let uiImage = object as? UIImage {
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
        let parts = split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let first = parts.first, !first.isEmpty else {
            return nil
        }

        let chars = Array(first)
        var firstChar: String

        if chars.first?.isEmoji == true {
            firstChar = String(chars[0])
        } else {
            if chars.count >= 2 {
                if chars[0].isLetter || chars[0].isNumber,
                   chars[1].isLetter || chars[1].isNumber
                {
                    firstChar = String(chars[0...1])
                } else {
                    firstChar = String(chars[0])
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

