//
//
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func snapshot(trigger: Bool, onComplete: @escaping (UIImage) -> Void) -> some View {
        modifier(SnaphotModifier(trigger: trigger, onComplete: onComplete))
    }
}

private struct SnaphotModifier: ViewModifier {
    var trigger: Bool
    var onComplete: (UIImage) -> Void
    /// Local View Modifier Properties
    @State private var view: UIView = .init(frame: .zero)

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { _, _ in
                    generateSnapshot()
                }
        } else {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { _ in
                    generateSnapshot()
                }
        }
    }

    private func generateSnapshot() {
        if let superView = view.superview?.superview {
            let renderer = UIGraphicsImageRenderer(size: superView.bounds.size)
            let image = renderer.image { _ in
                superView.drawHierarchy(in: superView.bounds, afterScreenUpdates: true)
            }
            onComplete(image)
        }
    }
}

private struct ViewExtractor: UIViewRepresentable {
    var view: UIView
    func makeUIView(context _: Context) -> UIView {
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}

#Preview {
    ContentView()
}
