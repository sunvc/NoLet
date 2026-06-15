//
//  CustomSlider.swift
//  StretchySlider
//
//  Created by Balaji Venkatesh on 07/02/24.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var isPress: Bool
    @Binding var sliderProgress: CGFloat
    /// Configuration
    var symbol: Symbol?
    var axis: SliderAxis
    var tint: Color
    /// View Properties
    @State private var progress: CGFloat = .zero
    @State private var dragOffset: CGFloat = .zero
    @State private var lastDragOffset: CGFloat = .zero
    var body: some View {
        GeometryReader {
            let size = $0.size
            let orientationSize = axis == .horizontal ? size.width : size.height
            let progressValue = (max(progress, .zero)) * orientationSize
            
            ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow( radius: 1)
                Rectangle()
                    .fill(tint.gradient)
                    .frame(
                        width: axis == .horizontal ? progressValue : nil,
                        height: axis == .vertical ? progressValue : nil
                    )
                
                if let symbol, symbol.display {
                    Image(systemName: symbol.icon)
                        .font(symbol.font)
                        .foregroundStyle(symbol.tint)
                        .padding(symbol.padding)
                        .frame(width: size.width, height: size.height, alignment: symbol.alignment)
                        .transition(.opacity)
                }
            }
            .clipShape(.rect(cornerRadius: 15))
            .contentShape(.rect(cornerRadius: 15))
            .optionalSizingModifiers(
                axis: axis,
                size: size,
                progress: progress,
                orientationSize: orientationSize
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged {
                        let translation = $0.translation
                        let movement = (axis == .horizontal ? translation.width : -translation.height) + lastDragOffset
                        dragOffset = movement
                        calculateProgress(orientationSize: orientationSize)
                        self.isPress = true
                    }
                    .onEnded { _ in
                        withAnimation(.smooth) {
                            dragOffset = dragOffset > orientationSize ? orientationSize : (dragOffset < 0 ? 0 : dragOffset)
                            calculateProgress(orientationSize: orientationSize)
                        }
                        self.isPress = false
                        lastDragOffset = dragOffset
                    }
            )
            .frame(
                maxWidth: size.width,
                maxHeight: size.height,
                alignment: axis == .vertical ? (progress < 0 ? .top : .bottom) : (progress < 0 ? .trailing : .leading)
            )
            .onChange(of: sliderProgress) { newValue in
                /// Initial Progress Settings
                guard newValue != progress else { return }
                progress = max(min(newValue, 1.0), .zero)
                dragOffset = progress * orientationSize
                lastDragOffset = dragOffset
            }
            .onChange(of: axis) { oldValue in
                dragOffset = progress * orientationSize
                lastDragOffset = dragOffset
            }
            .onAppear{
                progress = max(min(sliderProgress, 1.0), .zero)
                dragOffset = progress * orientationSize
                lastDragOffset = dragOffset
            }
        }
        .onChange(of: progress) { newValue in
            let clampedValue = max(min(newValue, 1.0), .zero)
            if clampedValue != sliderProgress {
                sliderProgress = clampedValue
            }
        }
        
    }
    
    /// Calculating Progress
    private func calculateProgress(orientationSize: CGFloat) {
        let topAndTrailingExcessOffset = orientationSize + (dragOffset - orientationSize) * 0.1
        let bottomAndLeadingExcessOffset = dragOffset < 0 ? (dragOffset * 0.1) : dragOffset
        
        let progress = (dragOffset > orientationSize ? topAndTrailingExcessOffset : bottomAndLeadingExcessOffset) / orientationSize
        
        // 防止 NaN 和无限值
        if progress.isFinite && !progress.isNaN {
            self.progress = progress
        }
    }
    
    /// Symbol Configuration
    struct Symbol {
        var icon: String
        var tint: Color
        var font: Font
        var padding: CGFloat
        var display: Bool = true
        var alignment: Alignment = .center
    }
    
    /// Slider Axis
    enum SliderAxis {
        case vertical
        case horizontal
    }
}

fileprivate extension View {
    @ViewBuilder
    func optionalSizingModifiers(axis: CustomSlider.SliderAxis, size: CGSize, progress: CGFloat, orientationSize: CGFloat) -> some View {
        let topAndTrailingScale = 1 - (progress - 1) * 0.15
        let bottomAndLeadingScale = 1 + (progress) * 0.15
        
        self
            .frame(
                width: axis == .horizontal && progress < 0 ? size.width + (-progress * size.width) : nil,
                height: axis == .vertical && progress < 0 ? size.height + (-progress * size.height) : nil
            )
            .scaleEffect(
                x: axis == .vertical ? (progress > 1 ? topAndTrailingScale : (progress < 0 ? bottomAndLeadingScale : 1)) : 1,
                y: axis == .horizontal ? (progress > 1 ? topAndTrailingScale : (progress < 0 ? bottomAndLeadingScale : 1)) : 1,
                anchor: axis == .horizontal ? (progress < 0 ? .trailing : .leading) : (progress < 0 ? .top : .bottom)
            )
    }
}

#Preview {
    ContentView()
}
