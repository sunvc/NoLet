//
//  PopView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/3/2.
//

import Foundation
import SwiftUI

/// Config
struct Config {
    var backgroundColor: Color = Color.primary.opacity(0.25)
    /// You can add extra properties here if you wish to.
}

/// It's a custom modifier
extension View {
    @ViewBuilder
    func popView<Content: View>(
        config: Config = .init(),
        isPresented: Binding<Bool>,
        onDismiss: @escaping () -> (),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .modifier(
                PopViewHelper(
                    config: config,
                    isPresented: isPresented,
                    onDismiss: onDismiss,
                    viewContent: content
                )
            )
    }
}

fileprivate struct PopViewHelper<ViewContent: View>: ViewModifier {
    var config: Config
    @Binding var isPresented: Bool
    var onDismiss: () -> ()
    @ViewBuilder var viewContent: ViewContent
    /// Local View Properties
    @State private var presentFullScreenCover: Bool = false
    @State private var animateView: Bool = false
    func body(content: Content) -> some View {
        /// UnMutable Properties
        let screenHeight = screenSize.height
        let animateView = animateView
        
        content
            .fullScreenCover(isPresented: $presentFullScreenCover, onDismiss: onDismiss) {
                ZStack {
                    Rectangle()
                        .fill(config.backgroundColor)
                        .ignoresSafeArea()
                        .opacity(animateView ? 1 : 0)
                    
                    if #available(iOS 17.0, *){
                        viewContent
                            .visualEffect({ content, proxy in
                                content
                                    .offset(y: offset(proxy, screenHeight: screenHeight, animateView: animateView))
                            })
                            .presentationBackground(.clear)
                            .task {
                                guard !animateView else { return }
                                withAnimation(.bouncy(duration: 0.4, extraBounce: 0.05)) {
                                    self.animateView = true
                                }
                            }
                            .ignoresSafeArea(.container, edges: .all)
                    }else{
                        viewContent
                            .task {
                                guard !animateView else { return }
                                withAnimation(.bouncy(duration: 0.4, extraBounce: 0.05)) {
                                    self.animateView = true
                                }
                            }
                            .ignoresSafeArea(.container, edges: .all)
                    }
                    
                   
                }
            }
            .onChange(of: isPresented) {newValue in
                if newValue {
                    toggleView(true)
                } else {
                    Task {
                        withAnimation(.snappy(duration: 0.45, extraBounce: 0)) {
                            self.animateView = false
                        }
                        
                        try? await Task.sleep(for: .seconds(0.2))
                        
                        toggleView(false)
                    }
                    
                    /// Or You can use the default SwiftUI Animation Completion Modifier
//                    withAnimation(.snappy(duration: 0.45, extraBounce: 0), completionCriteria: .logicallyComplete) {
//                        self.animateView = false
//                    } completion: {
//                        toggleView(false)
//                    }
                }
            }
    }
    
    func toggleView(_ status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        
        withTransaction(transaction) {
            presentFullScreenCover = status
        }
    }
    
    nonisolated func offset(_ proxy: GeometryProxy, screenHeight: CGFloat, animateView: Bool) -> CGFloat {
        let viewHeight = proxy.size.height
        return animateView ? 0 : (screenHeight + viewHeight) / 2
    }
    
    var screenSize: CGSize {
        var size: CGSize = .zero
         DispatchQueue.main.async{
            size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size ?? .zero
        }
        return size
    }
}

