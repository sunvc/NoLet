//
//  SlideToConfirm.swift
//  SlideControl
//
//  Created by Balaji Venkatesh on 07/04/25.
//

import SwiftUI

struct SlideToConfirm: View {
    var config: Config
    var disabled:Bool = false
    var onSwiped: () -> ()
    /// View Properties
    @State private var animateText: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var isCompleted: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let knobSize = size.height
            let maxLimit = size.width - knobSize
            let progress: CGFloat = isCompleted ? 1 : (offsetX / maxLimit)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        .gray.opacity(0.25)
                        .shadow(.inner(color: .black.opacity(0.2), radius: 10))
                    )
                
                /// Tint Capsule
                let extraCapsuleWidth = (size.width - knobSize) * progress
                
                Capsule()
                    .fill(config.tint.gradient)
                    .frame(width: knobSize + extraCapsuleWidth, height: knobSize)
                
                LeadingTextView(size, progress: progress)
                
                HStack(spacing: 0) {
                    KnobView(size, progress: progress, maxLimit: maxLimit)
                        .zIndex(1)
                    
                    ShimmerTextView(size, progress: progress)
                }
            }
        }
        /// Modify this as per your needs!
        .frame(height: (isCompleted && !disabled) ? 50 : config.height)
        .if(true){ view in
            Group{
                if #available(iOS 17.0, *) {
                    view
                        .containerRelativeFrame(.horizontal) { value, _ in
                            let ratio: CGFloat = (isCompleted && !disabled) ? 0.5 : 0.8
                            return value * ratio
                        }
                }else{
                    view
                }
            }
        }
//        .frame(maxWidth: 300)
        /// Disabling User Interaction When swipe confirmed
        .allowsHitTesting(!isCompleted)
    }
    
    /// Knob View
    func KnobView(_ size: CGSize, progress: CGFloat, maxLimit: CGFloat) -> some View {
        Circle()
            .fill(.background)
            .padding(config.knobPadding)
            .frame(width: size.height, height: size.height)
            .overlay {
                ZStack {
                    Image(systemName: "phone.arrow.right.fill")
                        .opacity(1 - progress)
                        .blur(radius: progress * 10)
                        .symbolEffect(.wiggle)
                    
                    Image(systemName: "checkmark")
                        .opacity(progress)
                        .blur(radius: (1 - progress) * 10)
                }
                .font(.title3.bold())
            }
            .contentShape(.circle)
            .scaleEffect((isCompleted && !disabled) ? 0.6 : 1, anchor: .center)
            .offset(x: isCompleted ? maxLimit : offsetX)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        offsetX = min(max(value.translation.width, 0), maxLimit)
                    }).onEnded({ value in
                        if offsetX == maxLimit {
                            onSwiped()
                            /// Stopping Shimmer Effect
                            animateText = false
                            
                            withAnimation(.smooth) {
                                isCompleted = true
                            }
                        } else {
                            withAnimation(.smooth) {
                                offsetX = 0
                            }
                        }
                    })
            )
    }
    
    /// Shimmer Text View
    func ShimmerTextView(_ size: CGSize, progress: CGFloat) -> some View {
        Text(isCompleted ? config.confirmationText : config.idleText)
            .foregroundStyle(.gray.opacity(0.6))
            .overlay {
                /// Shimmer Effect
                Rectangle()
                    .frame(height: 15)
                    .rotationEffect(.init(degrees: 90))
                    .if(true){view in
                        Group{
                            if #available(iOS 17.0, *) {
                                view
                                    .visualEffect { [animateText] content, proxy in
                                        content
                                            .offset(x: -proxy.size.width / 1.8)
                                            .offset(x: animateText ? proxy.size.width * 1.2 : 0)
                                    }
                            }else{
                                view
                            }
                        }
                    }
                
                    .mask(alignment: .leading) {
                        Text(isCompleted ? config.confirmationText : config.idleText)
                    }
                    .blendMode(.softLight)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            /// To Make it Center
            /// Eliminating knob's radius
            .padding(.trailing, size.height / 2)
            .mask {
                Rectangle()
                    .scale(x: 1 - progress, anchor: .trailing)
            }
            .frame(height: size.height)
            .task {
                guard !isCompleted && !animateText else { return }
                
                try? await Task.sleep(for: .seconds(0))
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    animateText = true
                }
            }
    }
    
    /// OnSwipe/Confirmation Text View
    func LeadingTextView(_ size: CGSize, progress: CGFloat) -> some View {
        ZStack {
            Text(config.onSwipeText)
                .opacity(isCompleted ? 0 : 1)
                .blur(radius: isCompleted ? 10 : 0)
            
            Text(config.confirmationText)
                .opacity(!isCompleted ? 0 : 1)
                .blur(radius: !isCompleted ? 10 : 0)
        }
        .fontWeight(.semibold)
        .foregroundStyle(config.foregorundColor)
        .frame(maxWidth: .infinity)
        /// To make it Center
        /// Since when completed the knob becomes smaller by scale modifier!
        .padding(.trailing, (size.height * (isCompleted ? 0.6 : 1)) / 2)
        .mask {
            Rectangle()
                .scale(x: progress, anchor: .leading)
        }
    }
    
    struct Config {
        var idleText: String
        var onSwipeText: String
        var confirmationText: String
        var tint: Color
        var foregorundColor: Color
        var height: CGFloat = 65
        /// Add Other Customization Properties as per your needs!
        var knobPadding: CGFloat = 5
    }
}

#Preview {
    SlideToConfirm(config: .init(
        idleText: "Swipe to Pay",
        onSwipeText: "Confirms Payment",
        confirmationText: "Success!",
        tint: .green,
        foregorundColor: .white
    ), disabled: true) {
        
    }
}
