//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - ReverseScrollView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/7 22:49.
    
import SwiftUI

struct ReverseScrollView<Content>: View where Content: View {
    @State private var contentHeight: CGFloat = CGFloat.zero
    @State private var scrollOffset: CGFloat = CGFloat.zero
    @State private var currentOffset: CGFloat = CGFloat.zero
    
    var content: () -> Content
    
    // Calculate content offset
    func offset(outerheight: CGFloat, innerheight: CGFloat) -> CGFloat {
        
        let totalOffset = currentOffset + scrollOffset
        return -((innerheight/2 - outerheight/2) - totalOffset)
    }
    
    var body: some View {
        GeometryReader { outerGeometry in
            // Render the content
            //  ... and set its sizing inside the parent
            self.content()
            .modifier(ViewHeightKey())
            .onPreferenceChange(ViewHeightKey.self) { self.contentHeight = $0 }
            .frame(height: outerGeometry.size.height)
            .offset(y: self.offset(outerheight: outerGeometry.size.height, innerheight: self.contentHeight))
            .clipped()
            .animation(.easeInOut, value: outerGeometry.size.height)
            .gesture(
                 DragGesture()
                    .onChanged({ self.onDragChanged($0) })
                    .onEnded({ self.onDragEnded($0, outerHeight: outerGeometry.size.height)}))
        }
    }
    
    func onDragChanged(_ value: DragGesture.Value) {
        // Update rendered offset
        self.scrollOffset = (value.location.y - value.startLocation.y)
    }
    
    func onDragEnded(_ value: DragGesture.Value, outerHeight: CGFloat) {
        // Update view to target position based on drag position
        let scrollOffset = value.location.y - value.startLocation.y
        let topLimit = self.contentHeight - outerHeight
        
        // Negative topLimit => Content is smaller than screen size. We reset the scroll position on drag end:
        if topLimit < 0 {
             self.currentOffset = 0
        } else {
            // We cannot pass bottom limit (negative scroll)
            if self.currentOffset + scrollOffset < 0 {
                self.currentOffset = 0
            } else if self.currentOffset + scrollOffset > topLimit {
                self.currentOffset = topLimit
            } else {
                self.currentOffset += scrollOffset
            }
        }
        self.scrollOffset = 0
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

extension ViewHeightKey: ViewModifier {
    func body(content: Content) -> some View {
        return content.background(GeometryReader { proxy in
            Color.clear.preference(key: Self.self, value: proxy.size.height)
        })
    }
}

