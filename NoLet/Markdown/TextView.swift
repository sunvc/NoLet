//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - TextView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/11/29 12:46.

import SwiftUI
import UIKit

//let ns = NSAttributedString(string: "\n\(url)", attributes: [
//    .font: UIFont.systemFont(ofSize: 25),
//    .foregroundColor: Color.yellow,
//    .link: url,
//])

struct TextView: UIViewRepresentable {
    var text: NSAttributedString

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator

        view.dataDetectorTypes = [.phoneNumber, .link]

        view.isScrollEnabled = false
        view.isEditable = false
        view.isUserInteractionEnabled = true
        view.isSelectable = true
        view.backgroundColor = .clear

        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let dimensions = text.boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return .init(width: width, height: ceil(dimensions.height))
    }
}

extension TextView {
    final class Coordinator: NSObject, UITextViewDelegate {
        private var textView: TextView

        init(_ textView: TextView) {
            self.textView = textView
            super.init()
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            self.textView.text = textView.attributedText
        }
    }
}
