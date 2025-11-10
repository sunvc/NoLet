//
//  AnimatedButton.swift
//  AnimatedStateButton
//
//  Created by Balaji Venkatesh on 18/03/25.
//

import SwiftUI

struct AnimatedButton: View {
    @Binding var state:buttonState
    var config: Config
    var loadings: [Config]
    var success: Config
    var fail: Config
    var shape: AnyShape
    var onTap: (Self) async -> ()
    
  
    var currentConfig:Config{
        switch state {
        case .normal: config
        case .loading(let index): loadings[ min(max(index, 0), loadings.count - 1)]
        case .success: success
        case .fail: fail
        }
    }
    
    
    init(state:Binding<buttonState>, normal: Config? = nil, success: Config? = nil, fail: Config? = nil, loadings: [Config]? = nil, shape: AnyShape = .init(.capsule), onTap: @escaping (Self) async  -> Void) {
        self._state = state
        self.config = normal ?? .init(title: "普通按钮", foregroundColor: .red, background: .white)
        self.success = success ?? .init(title: "成功", foregroundColor: .black, background: .green)
        self.fail = fail ?? .init(title: "失败", foregroundColor: .white, background: .red)
        self.loadings = loadings ?? [.init(title: "请等待...", foregroundColor: .white, background: .red)]
        self.shape = shape
        self.onTap = onTap
    }
    
    var isLoading:Bool{  state != .normal && state != .fail && state != .success }
    
    var body: some View {
        Button {
            Task {
                if state == .normal{
                    await onTap(self)
                }
            }
        } label: {
            HStack(spacing: 10) {
                
                if isLoading {
                    if #available(iOS 17.0, *) {
                        Spinner(tint: currentConfig.foregroundColor, lineWidth: 4)
                            .frame(width: 20, height: 20)
                            .transition(.blurReplace)
                    } else {
                        // Fallback on earlier versions
                        Spinner(tint: currentConfig.foregroundColor, lineWidth: 4)
                    }
                }else {
                    if let symbolImage = currentConfig.symbolImage {
                        if #available(iOS 17.0, *) {
                            Image(systemName: symbolImage)
                                .font(.title3)
                                .contentTransition(.symbolEffect)
                                .transition(.blurReplace)
                        } else {
                            // Fallback on earlier versions
                            Image(systemName: symbolImage)
                                .font(.title3)
                                .contentTransition(.opacity)
                        }
                    }
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
        /// Disabling Button when Task is Performing
        .disabled(isLoading)
        /// Let's create a custom button style which uses scale animation rather than default opacity animation
        .buttonStyle(ScaleButtonStyle())
        .animation(currentConfig.animation, value: currentConfig)
        .animation(currentConfig.animation, value: isLoading)
    }
    
    
    enum buttonState: Equatable{
        case normal
        case loading(Int)
        case success
        case fail
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
        var state:buttonState = .normal
    }
    
    /// **切换到下一个配置**
   func next(_ state:buttonState? = nil, delay:Double = 1, complete:(()-> Void)? = nil) async {
        
        if let state = state {
            self.state = state
            if state == .success || state == .fail{
                try? await Task.sleep(for: .seconds(delay))
                self.state = .normal
                try? await Task.sleep(for: .seconds(0.5))
                complete?()
            }
        }else {
            switch self.state {
            case .normal:
                self.state = .loading(0)
            case .loading(let index):
                if index == 1{
                    self.state = .loading(index - 1)
                }else if index >= loadings.count - 1{
                    self.state = .success
                    
                    try? await Task.sleep(for: .seconds(delay))
                    self.state = .normal
                    try? await Task.sleep(for: .seconds(0.5))
                    complete?()
                }else {
                    self.state = .loading(index - 1)
                }
            case .success, .fail:
                try? await Task.sleep(for: .seconds(delay))
                self.state = .normal
                try? await Task.sleep(for: .seconds(0.5))
                complete?()
            }
        }
    }
    
}

fileprivate struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17.0, *) {
            configuration.label
                .animation(.linear(duration: 0.2)) {
                    $0.scaleEffect(configuration.isPressed ? 0.9 : 1)
                }
        } else {
            // Fallback on earlier versions
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .animation(.linear(duration: 0.2), value: configuration.isPressed)
        }
    }
}

struct Spinner: View {
    var tint: Color
    var lineWidth: CGFloat = 4
    /// View Properties
    @State private var rotation: Double = 0
    @State private var extraRotation: Double = 0
    @State private var isAnimatedTriggered: Bool = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.3), style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            
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

#Preview {
    ContentView()
}
