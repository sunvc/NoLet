//
//  TouchCaptureView.swift
//  pushme
//
//  Created by lynn on 2025/7/30.
//
import SwiftUI

extension View{
    
    func pbutton( _ hasMoveTopRight:Binding<Bool>,_ isPress:Binding<Bool>,     onBegan: @escaping ()->Void, onEnded: @escaping ()->Void,onCancelled:(()-> Void)? = nil ) -> some View{
        self
            .overlay {
                TouchCaptureView(hasMoveTopRight: hasMoveTopRight,isPressing: isPress, onBegan: onBegan, onEnded: onEnded, onCancelled: onCancelled)
            }
    }
    
    func customTalkSheet<T: View>(show: Binding<Bool>, size: CGSize, @ViewBuilder content: @escaping () -> T) -> some View {
        modifier(CustomSheetForTalk(show: show, size: size, subView: content))
    }
}

struct TouchCaptureView: UIViewRepresentable {
    @Binding var hasMoveTopRight: Bool
    @Binding var isPressing: Bool
    var onBegan: () -> Void
    var onEnded: () -> Void
    var onCancelled: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> UIView {
        let view = TouchUIView()
        view.coordinator = context.coordinator
        view.onBegan = onBegan
        view.onEnded = onEnded
        view.onCancelled = onCancelled
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(hasMoveTopRight: $hasMoveTopRight, isPressing: $isPressing)
    }
    
    class Coordinator {
        var hasMoveTopRight: Binding<Bool>
        var isPressing: Binding<Bool>
        var lastTouchTime: Date? // ⏱ 记录上次点击时间
        
        init(hasMoveTopRight: Binding<Bool>, isPressing: Binding<Bool>) {
            self.hasMoveTopRight = hasMoveTopRight
            self.isPressing = isPressing
        }
    }
    
    class TouchUIView: UIView {
        var coordinator: Coordinator?
        var onBegan: (() -> Void)?
        var onEnded: (() -> Void)?
        var onCancelled: (() -> Void)?
        private var touchStartTime: Date?
  
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let coord = coordinator else { return }
            
            let now = Date()
            if let last = coord.lastTouchTime,
               now.timeIntervalSince(last) < 0.5 {
                return
            }
            coord.lastTouchTime = now
            
            coord.hasMoveTopRight.wrappedValue = false
            coord.isPressing.wrappedValue = true
            touchStartTime = now
            onBegan?()
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            coordinator?.isPressing.wrappedValue = false
            
            guard let start = touchStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            
            touchStartTime = nil
            
            if elapsed < 0.3 || coordinator?.hasMoveTopRight.wrappedValue == true{
                coordinator?.hasMoveTopRight.wrappedValue = true
                onCancelled?()
            }else{
                onEnded?()
            }
            
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            coordinator?.isPressing.wrappedValue = true
            onCancelled?()
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = bounds.width / 2 - 15
            let distance = hypot(location.x - center.x, location.y - center.y)
            let isInsideCircle = distance <= radius
            if coordinator?.hasMoveTopRight.wrappedValue != !isInsideCircle {
                coordinator?.hasMoveTopRight.wrappedValue = !isInsideCircle
            }
        }
        
        
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2 - 15
            let distance = hypot(point.x - center.x, point.y - center.y)
            return distance <= radius
        }
    }
}







struct CustomSheetForTalk<Sub: View>: ViewModifier{
    @Binding var show:Bool
    var size: CGSize
    @ViewBuilder var subView: () -> Sub
    func body(content: Content) -> some View {
        
        content
            .fullScreenCover(isPresented: $show) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.gray.opacity(0.001))
                        .onTapGesture {
                            Haptic.impact()
                            self.show.toggle()
                        }
                    
                    subView()
                        .frame(width: size.width, height: size.height)
                        .background(.ultraThinMaterial)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 30))
                }
                
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .background(Color.clear)
                .background(BackgroundClearView())
                .ignoresSafeArea()
                
            }
    }
    
    
}


extension Font{
    static func numberStyle(size: CGFloat = 32) -> Self{
        .custom("Digital-7 Mono", size: size)
    }
}

struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct HourAndMinuteView: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    
    
    var body: some View {
        Text(timeString(from: currentTime))
            .onReceive(timer) { input in
                currentTime = input
            }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"  // 24小时制，如果要12小时制改成 "hh:mm a"
        return formatter.string(from: date)
    }
}


#Preview {
    PushToTalkView()
}
