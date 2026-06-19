//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - CustomTextView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/19 08:10.
    
import SwiftUI


final class SelectableTextView: UITextView {

    override func copy(_ sender: Any?) {
        super.copy(sender)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.selectedRange = NSRange(location: 0, length: 0)
            self.resignFirstResponder()
            Toast.copy()
        }
    }
    
    override func editMenu(
        for textRange: UITextRange,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {

        let deselectAction = UIAction(
            title: "取消",
            image: UIImage(systemName: "xmark")
        ) { [weak self] _ in
            self?.selectedTextRange = nil
        }
        
        var suggestedActions = suggestedActions
        
        suggestedActions.insert(deselectAction, at: 1)

        return UIMenu(children: suggestedActions)
    }
 
}

struct SCSelectableTextRepresentable: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let textAlignment: NSTextAlignment
    let lineLimit: Int?

    func makeUIView(context: Context) -> SelectableTextView {
        let textView = SelectableTextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: SelectableTextView, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.textColor = textColor
        uiView.textAlignment = textAlignment
        uiView.textContainer.maximumNumberOfLines = lineLimit ?? 0
        uiView.textContainer.lineBreakMode = lineLimit == nil ? .byWordWrapping : .byTruncatingTail
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: SelectableTextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else {
            return nil
        }

        let targetSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let fittedSize = uiView.sizeThatFits(targetSize)
        return CGSize(width: width, height: ceil(fittedSize.height))
    }
    
}

