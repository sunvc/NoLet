//
//  View+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo 2024/8/9.
//

import Combine
import Foundation
import SwiftUI
import PhotosUI


struct CustomForegroundStyleModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var s1: Color
    var s2: Color? = nil
    var s3: Color? = nil

    var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var primary: Color {
        s1 == .primary ? primaryColor : s1
    }

    var secondary: Color? {
        if let s2 = s2 {
            return s2 == .primary ? primaryColor : s2
        }
        return nil
    }

    var tertiary: Color? {
        if let s3 = s3 {
            return s3 == .primary ? primaryColor : s3
        }
        return nil
    }

    func body(content: Content) -> some View {
        if let secondary, let tertiary {
            content
                .foregroundStyle(primary, secondary, tertiary)
        } else if let secondary {
            content
                .foregroundStyle(primary, secondary)
        } else {
            content
                .foregroundStyle(primary)
        }
    }
}



// MARK: - BackgroundStyle 视图

struct OutlineOverlay: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    .linearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.6 : 0.3),
                            .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.overlay)
        )
    }
}

// MARK: - buttons 视图

struct ButtonPress: ViewModifier {
    var releaseStyles: Double = 0.0
    var maxX: Double = 0.0
    var changeHaptic: Bool = false
    var onRelease: ((DragGesture.Value) -> Bool)? = nil

    @GestureState private var isPressed = false
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.99 : 1)
            .opacity(isPressed ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed, body: { _, state, _ in
                        state = true
                    })
                    .onEnded { result in
                        if changeHaptic {
                            if let success = onRelease?(result), success {
                                Haptic.impact()
                            }
                        } else {
                            if abs(result.translation.width) <= maxX,
                               let success = onRelease?(result), success
                            {
                                Haptic.impact()
                            }
                        }
                    }
            )
    }
}

// MARK: - TextFieldModifier

struct TextFieldModifier: ViewModifier {
    var icon: String
    var background: Bool = true
    var complete: (() -> Void)? = nil

    func body(content: Content) -> some View {
        content
            .overlay(
                HStack {
                    Image(systemName: icon)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .modifier(OutlineOverlay(cornerRadius: 14))
                        .offset(x: -46)
                        .accessibility(hidden: true)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.tint, .secondary)
                        .onTapGesture {
                            complete?()
                            Haptic.impact()
                        }
                    Spacer()
                }
            )
            .padding()
            .padding(.leading, 43)
            .if(background) {
                $0.background(.ultraThinMaterial)
            }
            .cornerRadius(20)
            .modifier(OutlineOverlay(cornerRadius: 20))
    }
}

struct ListButton<LEFT: View, Trailing: View>: View {
    @ViewBuilder var leading: () -> LEFT
    @ViewBuilder var trailing: () -> Trailing
    var action: () -> Bool
    var showRight: Bool

    init(
        @ViewBuilder leading: @escaping () -> LEFT,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        showRight: Bool = true,
        action: @escaping () -> Bool
    ) {
        self.leading = leading
        self.trailing = trailing
        self.action = action
        self.showRight = showRight
    }

    var body: some View {
        Button {
            if action() {
                Haptic.impact()
            }
        } label: {
            HStack {
                leading()
                Spacer()
                trailing()
                if showRight {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
        .tint(.primary)
        .buttonStyle(.borderless)
    }
}




extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    /// https://www.avanderlee.com/swiftui/conditional-view-modifier/
    @ViewBuilder func `if`<Content: View>(
        _ condition: Bool,
        _ transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder nonisolated func `if`<Content: View>(
        _ condition: Bool,
        _ transform: () -> Content
    ) -> some View {
        if condition {
            transform()
        } else {
            self
        }
    }

    @ViewBuilder nonisolated func diff<Content: View>(_ transform: (Self) -> Content) -> some View {
        transform(self)
    }


    func customField(
        icon: String,
        _ background: Bool = true,
        complete: (() -> Void)? = nil
    ) -> some View {
        modifier(TextFieldModifier(icon: icon, background: background, complete: complete))
    }


    @available(iOS, deprecated: 26.0, message: "谨慎使用,这个代码影响手势识别")
    func VButton(
        _ maxX: Double = 0.0,
        release: Double = 0.0,
        changeHaptic: Bool = false,
        onRelease: ((DragGesture.Value) -> Bool)? = nil
    ) -> some View {
        modifier(ButtonPress(
            releaseStyles: release,
            maxX: maxX,
            changeHaptic: changeHaptic,
            onRelease: onRelease
        ))
    }

    @available(iOS, deprecated: 26.0, message: "谨慎使用,这个代码影响手势识别")
    func VButton(
        changeHaptic: Bool = false,
        onRelease: @escaping (DragGesture.Value) -> Bool
    ) -> some View {
        modifier(ButtonPress(
            releaseStyles: 0,
            maxX: 0,
            changeHaptic: changeHaptic,
            onRelease: onRelease
        ))
    }

    @ViewBuilder
    func customPresentationCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationCornerRadius(radius)
        } else {
            self
        }
    }

    func customForegroundStyle(_ s1: Color, _ s2: Color? = nil, _ s3: Color? = nil) -> some View {
        modifier(CustomForegroundStyleModifier(s1: s1, s2: s2, s3: s3))
    }

    @ViewBuilder
    func background26<S>(_ color: S, radius: CGFloat = 0) -> some View where S: ShapeStyle {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
        } else {
            background(RoundedRectangle(cornerRadius: radius).fill(color))
        }
    }


    public func button26<S>(_ style: S) -> some View where S: PrimitiveButtonStyle {
        Group {
            if #available(iOS 26.0, *) {
                self
                    .buttonStyle(.glass)
            } else {
                self.buttonStyle(style)
            }
        }
    }

    @ViewBuilder
    nonisolated func glassCard(
        _ radius: CGFloat = 12,
        padding: CGFloat = 0,
        borderColor: Color? = nil
    ) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
            } else {
                self.background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            }
        }
        .diff { view in
            Group {
                if let borderColor {
                    view
                        .overlay(
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .stroke(borderColor.opacity(0.6), lineWidth: 1)
                        )
                } else {
                    if #unavailable(iOS 26.0) {
                        view
                            .overlay(
                                RoundedRectangle(cornerRadius: radius, style: .continuous)
                                    .stroke(.primary.opacity(0.6), lineWidth: 1)
                            )
                    }else{
                        view
                    }
                    
                }
            }
        }
        .padding(padding)
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view
                } else {
                    view
                        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius))
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



extension View {
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
