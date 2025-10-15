//
//  ToastView.swift
//  pushback
//
//  Created by lynn on 2025/5/18.
//
import SwiftUI


class Toast: ObservableObject {
    static let shared = Toast()
    private init() { }
    @Published fileprivate var toasts: [ToastItem] = []
    
    
    func present(title: String, symbol: String?, tint: Color = .primary,isUserInteractionEnabled:Bool = true, timing: ToastTime = .medium) {

        DispatchQueue.main.async{
            UIAccessibility.post(notification: .announcement, argument: title)
            withAnimation(.snappy) {
                self.toasts.append(
                    .init(
                        title: title,
                        symbol: symbol,
                        tint: tint,
                        isUserInteractionEnabled: true,
                        timing: timing
                    )
                )
            }
        }
    }
    
    func present(title: String, symbol: ToastSymbol?, tint: Color = .primary,isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
        
        DispatchQueue.main.async{
            UIAccessibility.post(notification: .announcement, argument: title)
            withAnimation(.snappy) {
                self.toasts.append(
                    .init(
                        title: title,
                        symbol: symbol?.rawValue,
                        tint: symbol != nil ? symbol!.color  : tint,
                        isUserInteractionEnabled: isUserInteractionEnabled,
                        timing: timing
                    )
                )
            }
        }
        
    
    }
    
    
    class func success(title: String.LocalizationValue, isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
        Toast.shared.present(title: String(localized: title), symbol: .success, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing)
    }
    class func info(title: String.LocalizationValue, isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
        Toast.shared.present(title: String(localized: title), symbol: .info, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing)
    }
    class  func question(title: String.LocalizationValue, isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
        Toast.shared.present(title: String(localized: title), symbol: .question, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing)
    }
    class func error(title: String.LocalizationValue, isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
        Toast.shared.present(title: String(localized: title), symbol: .error, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing)
    }
    class func copy(title: String.LocalizationValue, isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
        Toast.shared.present(title: String(localized: title), symbol: .copy, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing)
    }
}

struct ToastItem: Identifiable {
    let id: UUID = .init()
    /// Custom Properties
    var title: String
    var symbol: String?
    var tint: Color
    var isUserInteractionEnabled: Bool
    /// Timing
    var timing: ToastTime = .medium
}

enum ToastTime: CGFloat {
    case short = 1.0
    case medium = 3.0
    case long = 5.0
}

enum ToastSymbol: String{
    case success = "checkmark.bubble"
    case info = "info.bubble"
    case question = "questionmark.circle"
    case error = "xmark.app"
    case copy = "doc.on.doc"
    
    var color:Color{
        switch self {
        case .success: .green
        case .info: .orange
        case .question: .yellow
        case .error: .red
        case .copy: .green
        }
    }
}


struct ToastGroup: View {
    @ObservedObject var model = Toast.shared
    @StateObject private var manager = AppManager.shared

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            ZStack {
               
                ZStack{
                    ForEach(model.toasts) { toast in
                        ToastView(size: size, item: toast)
                            .scaleEffect(scale(toast))
                            .offset(y: offsetY(toast))
                            .zIndex(Double(model.toasts.firstIndex(where: { $0.id == toast.id }) ?? 0))
                    }
                }
                
                
            }
            .padding(.bottom, safeArea.top == .zero ? 15 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .safeAreaInset(edge: .top) {
                if manager.speaking{
                    MusicInfo()
                        .frame(height: 60)
                        .diff{ view in
                            Group{
                                if #available(iOS 26.0, *){
                                    view
                                        .glassEffect(
                                            .regular.interactive(),
                                            in: .rect(cornerRadius: 5)
                                        )

                                }else{
                                    view
                                        .background(.ultraThinMaterial)

                                }
                            }
                        }
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                            .animation(.easeInOut)
                        )

                }
            }
        }
    }
    
    func offsetY(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return (totalCount - index) >= 2 ? -20 : ((totalCount - index) * -10)
    }
    
    func scale(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return 1.0 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
    }
}

fileprivate struct ToastView: View {
    var size: CGSize
    var item: ToastItem
    /// View Properties
    @State private var delayTask: DispatchWorkItem?
    var body: some View {
        HStack(spacing: 0) {
            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .padding(.trailing, 10)
            }
            
            Text(item.title)
                .accessibilityLabel(item.title)
        }
        .foregroundStyle(item.tint)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .diff{ view in
            Group{
                if #available(iOS 26.0, *){
                    view
                        .glassEffect(.regular.interactive(), in: .capsule)
                }else{
                    view
                        .background(
                            .background
                                .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
                                .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
                            in: .capsule

                        )
                }
            }
        }

        .contentShape(.capsule)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded({ value in
                    guard item.isUserInteractionEnabled else { return }
                    let endX = value.translation.width
                    
                    
                    if abs(endX) > 10 {
                        /// Removing Toast
                        removeToast()
                        Haptic.impact(.light)
                    }
                })
        )
        .onAppear {
            guard delayTask == nil else { return }
            delayTask = .init(block: {
                removeToast()
            })
            
            if let delayTask {
                DispatchQueue.main.asyncAfter(deadline: .now() + item.timing.rawValue, execute: delayTask)
            }
        }
        /// Limiting Size
        .frame(maxWidth: size.width * 0.7)
        .transition(.offset(y: 150))
    
    }
    
    func removeToast() {
        if let delayTask {
            delayTask.cancel()
        }
        
        withAnimation(.snappy) {
            Toast.shared.toasts.removeAll(where: { $0.id == item.id })
        }
    }
}

