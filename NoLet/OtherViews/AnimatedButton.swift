//
//  AnimatedButton.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/2.
//

import SwiftUI

struct AnimatedButton: View {
    @StateObject private var handle = Handle()

    var config: Config
    var shape: AnyShape
    var onTap: (Handle) async -> Void

    init(
        normal: Config? = nil,
        shape: AnyShape = .init(.capsule),
        onTap: @escaping (Handle) async -> Void
    ) {
        config = normal ?? Config(style: .new)
        self.shape = shape
        self.onTap = onTap
    }

    var isLoading: Bool {
        if case .loading = handle.state { return true }
        return false
    }

    var currentConfig: Config {
        switch handle.state {
        case .normal:
            return self.config
        case .loading(let config),
             .success(let config),
             .fail(let config):
            return config
        }
    }

    var body: some View {
        Button {
            Task {
                if case .normal = handle.state {
                    await onTap(handle)
                }
            }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    Group {
                        if #available(iOS 17.0, *) {
                            Spinner(tint: currentConfig.foregroundColor, lineWidth: 4)
                                .transition(.blurReplace)
                        } else {
                            Spinner(tint: currentConfig.foregroundColor, lineWidth: 4)
                        }
                    }
                    .frame(width: 20, height: 20)
                } else if let symbolImage = currentConfig.symbolImage {
                    Group {
                        if #available(iOS 17.0, *) {
                            Image(systemName: symbolImage)
                                .contentTransition(.symbolEffect)
                                .transition(.blurReplace)
                        } else {
                            Image(systemName: symbolImage)
                                .contentTransition(.opacity)
                        }
                    }
                    .font(.title3)
                }

                Text(currentConfig.title)
                    .contentTransition(.interpolate)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, currentConfig.hPadding)
            .padding(.vertical, currentConfig.vPadding)
            .foregroundStyle(currentConfig.foregroundColor)
            .background(currentConfig.background.gradient)
            .clipShape(shape)
            .contentShape(shape)
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
        .animation(currentConfig.animation, value: currentConfig)
        .animation(currentConfig.animation, value: isLoading)
    }

    enum State: Equatable {
        case normal
        case loading(Config)
        case success(Config)
        case fail(Config)
    }

    struct Config: Equatable {
        var id = UUID()
        var title: String
        var foregroundColor: Color = .white
        var background: Color = .blue
        var symbolImage: String?
        var hPadding: CGFloat = 15
        var vPadding: CGFloat = 10
        var animation: Animation = .easeInOut(duration: 0.25)

        init(
            id: UUID = UUID(),
            title: String.LocalizationValue? = nil,
            foregroundColor: Color? = nil,
            background: Color? = nil,
            symbolImage: String? = nil,
            hPadding: CGFloat? = nil,
            vPadding: CGFloat? = nil,
            animation: Animation? = nil,
            style: Style = .new
        ) {
            switch style {
            case .success:
                self.id = id
                self.title = String(localized: title ?? "成功")
                self.foregroundColor = foregroundColor ?? .black
                self.background = background ?? .green

            case .fail:
                self.id = id
                self.title = String(localized: title ?? "失败")
                self.foregroundColor = foregroundColor ?? .white
                self.background = background ?? .red

            case .loading:
                self.id = id
                self.title = String(localized: title ?? "请等待...")
                self.foregroundColor = foregroundColor ?? .white
                self.background = background ?? .red

            case .new:
                self.id = id
                self.title = String(localized: title ?? "确定")
                self.foregroundColor = foregroundColor ?? .white
                self.background = background ?? .blue
            }

            self.symbolImage = symbolImage
            self.hPadding = hPadding ?? 15
            self.vPadding = vPadding ?? 10
            self.animation = animation ?? .easeInOut(duration: 0.25)
        }

        enum Style {
            case success
            case fail
            case loading
            case new
        }
    }

    @MainActor
    final class Handle: ObservableObject {
        @Published var state: State = .normal

        func loading(
            id: UUID = UUID(),
            title: String.LocalizationValue? = nil,
            foregroundColor: Color? = nil,
            background: Color? = nil,
            symbolImage: String? = nil,
            hPadding: CGFloat? = nil,
            vPadding: CGFloat? = nil,
            animation: Animation? = nil,
            style: Config.Style = .loading
        ) async {
            state = .loading(Config(
                id: id,
                title: title,
                foregroundColor: foregroundColor,
                background: background,
                symbolImage: symbolImage,
                hPadding: hPadding,
                vPadding: vPadding,
                animation: animation,
                style: style
            ))
        }

        func succeed(
            id: UUID = UUID(),
            title: String.LocalizationValue? = nil,
            foregroundColor: Color? = nil,
            background: Color? = nil,
            symbolImage: String? = nil,
            hPadding: CGFloat? = nil,
            vPadding: CGFloat? = nil,
            animation: Animation? = nil,
            style: Config.Style = .success,
            delay: Double = 1,
            complete: (() -> Void)? = nil
        ) async {
            await finish(.success(Config(
                id: id,
                title: title,
                foregroundColor: foregroundColor,
                background: background,
                symbolImage: symbolImage,
                hPadding: hPadding,
                vPadding: vPadding,
                animation: animation,
                style: style
            )), delay: delay, complete: complete)
        }

        func fail(
            id: UUID = UUID(),
            title: String.LocalizationValue? = nil,
            foregroundColor: Color? = nil,
            background: Color? = nil,
            symbolImage: String? = nil,
            hPadding: CGFloat? = nil,
            vPadding: CGFloat? = nil,
            animation: Animation? = nil,
            style: Config.Style = .fail,
            delay: Double = 1,
            complete: (() -> Void)? = nil
        ) async {
            await finish(.fail(Config(
                id: id,
                title: title,
                foregroundColor: foregroundColor,
                background: background,
                symbolImage: symbolImage,
                hPadding: hPadding,
                vPadding: vPadding,
                animation: animation,
                style: style
            )), delay: delay, complete: complete)
        }

        private func finish(_ state: State, delay: Double, complete: (() -> Void)?) async {
            self.state = state
            try? await Task.sleep(for: .seconds(delay))
            self.state = .normal
            try? await Task.sleep(for: .seconds(0.5))
            complete?()
        }
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .animation(.linear(duration: 0.2)) {
                    $0.scaleEffect(configuration.isPressed ? 0.9 : 1)
                }
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .animation(.linear(duration: 0.2), value: configuration.isPressed)
        }
    }
}

struct Spinner: View {
    var tint: Color
    var lineWidth: CGFloat = 4
    @State private var rotation: Double = 0
    @State private var extraRotation: Double = 0
    @State private var isAnimatedTriggered: Bool = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    tint.opacity(0.3),
                    style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(tint, style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.init(degrees: rotation))
                .rotationEffect(.init(degrees: extraRotation))
        }
        .compositingGroup()
        .onAppear(perform: animate)
    }

    private func animate() {
        guard !isAnimatedTriggered else { return }
        isAnimatedTriggered = true

        withAnimation(.linear(duration: 0.7).speed(1.2).repeatForever(autoreverses: false)) {
            rotation += 360
        }

        withAnimation(.linear(duration: 1).speed(1.2).delay(1).repeatForever(autoreverses: false)) {
            extraRotation += 360
        }
    }
}
