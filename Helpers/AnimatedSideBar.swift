//
//  AnimatedSideBar.swift
//  NoLet
//
//  Created by uuneo on 2025/2/24.
//

import SwiftUI

struct AnimatedSideBar<Content: View, MenuView: View, Background: View>: View {
    /// Customization Options
    var rotatesWhenExpands: Bool = true
    var disablesInteraction: Bool = true
    var sideMenuWidth: CGFloat = 200
    var cornerRadius: CGFloat = 25
    @Binding var showMenu: Bool
    @ViewBuilder var content: (UIEdgeInsets) -> Content
    @ViewBuilder var menuView: (UIEdgeInsets) -> MenuView
    @ViewBuilder var background: Background
    var slideLeft:(()-> Void)? = nil
    var slideRight:(()-> Void)? = nil
    /// View Properties
    @State private var isDragging: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var lastOffsetX: CGFloat = 0
    /// Used to Dim Content View When Side Bar is Being Dragged
    @State private var progress: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets ?? .zero
            
            HStack(spacing: 0) {
                GeometryReader { _ in
                    menuView(safeArea)
                        .disabled(isDragging)
                }
                .frame(width: sideMenuWidth)
                /// Clipping Menu Interaction Beyond it's Width
                .contentShape(.rect)
                
                GeometryReader { _ in
                    content(safeArea)
                }
                .frame(width: size.width)
                .overlay {
                    if disablesInteraction && progress > 0 {
                        Rectangle()
                            .fill(.black.opacity(progress * (colorScheme == .dark ? 0.5 : 0.2)))
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                    reset()
                                }
                            }
                    }
                }
                .mask {
                    RoundedRectangle(cornerRadius: progress * cornerRadius)
                }
                .scaleEffect(rotatesWhenExpands ? 1 - (progress * 0.1) : 1, anchor: .trailing)
                .rotation3DEffect(
                    .init(degrees: rotatesWhenExpands ? (progress * -15) : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
            }
            .frame(width: size.width + sideMenuWidth, height: size.height)
            .offset(x: -sideMenuWidth)
            .offset(x: offsetX)
            .contentShape(.rect)
            .simultaneousGesture(dragGesture)
        }
        .background(background)
        .ignoresSafeArea()
        .onChange(of: showMenu) { newValue in
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                if newValue {
                    showSideBar()
                } else {
                    reset()
                }
            }
        }
    }
    
    /// Drag Gesture
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // 计算水平和垂直的位移
                let horizontalTranslation = value.translation.width
                let verticalTranslation = value.translation.height
                
                // 只在水平移动大于垂直移动时生效，避免误触
                guard abs(horizontalTranslation) > abs(verticalTranslation),
                      value.startLocation.x > 20 else { return }
                
                // 如果 showSideBar 为 true，忽略向右滑动
                if showMenu && horizontalTranslation > 0 {
                    if horizontalTranslation > 150{
                        slideLeft?()
                    }
                    return
                }
                
                // 如果 showSideBar 为 false，忽略向左滑动
                if !showMenu && horizontalTranslation < 0 {
                    if horizontalTranslation < -150{
                        slideRight?()
                    }
                   
                    return
                }
                
                self.isDragging = true
                let translationX = max(min(horizontalTranslation + lastOffsetX, sideMenuWidth), 0)
                offsetX = translationX
                calculateProgress()
            }
            .onEnded { value in
                guard isDragging else { return }
                
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    let velocityX = value.velocity.width / 8
                    let total = velocityX + offsetX
                    
                    if total > (sideMenuWidth * 0.5) {
                        showSideBar()
                    } else {
                        reset()
                    }
                }
                self.isDragging = false
            }
    }

    
    /// Show's Side Bar
    func showSideBar() {
        offsetX = sideMenuWidth
        lastOffsetX = offsetX
        showMenu = true
        calculateProgress()
        Haptic.impact(.heavy)
    }
    
    /// Reset's to it's Initial State
    func reset() {
        offsetX = 0
        lastOffsetX = 0
        showMenu = false
        calculateProgress()
        Haptic.impact(.heavy)
    }
    
    /// Convert's Offset into Series of progress ranging from 0 - 1
    func calculateProgress() {
        progress = max(min(offsetX / sideMenuWidth, 1), 0)
    }
    
}
