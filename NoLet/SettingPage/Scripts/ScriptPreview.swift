//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptPreview.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/11 20:49.

import SwiftUI
import UIKit

struct ScriptPreview: View {
    var file: URL
    @State private var editMode: EditMode = .inactive
    @State private var content: String = ""
    @State private var showSaveConfirm: Bool = false

    init(file: URL) {
        self.file = file
        if let content = try? String(contentsOf: file, encoding: .utf8) {
            self._content = State(wrappedValue: content)
        }
    }

    var body: some View {
        // FIXME: 滚动条有问题,不知道啥问题 暂时禁用了
        LineNumberedTextEditor(text: $content, isEditable: editMode.isEditing)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(file.lastPathComponent)
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editMode == .active ? "保存" : "编辑") {
                        if editMode == .active {
                            showSaveConfirm = true
                        } else {
                            editMode = .active
                        }
                    }
                    .tint(editMode == .active ? .red : nil)
                }
            }
            .alert("保存修改？", isPresented: $showSaveConfirm) {
                Button("取消", role: .cancel) {
                    self.editMode = .inactive
                }
                Button("确认保存") {
                    save()
                    self.editMode = .inactive
                }
            } message: {
                Text("是否保存对 \(file.lastPathComponent) 的修改？")
            }
    }

    private func save() {
        do {
            guard let data = content.data(using: .utf8) else { return }
            try data.write(to: file)
            Toast.success(title: "保存成功")
        } catch {
            logger.error("\(error.localizedDescription)")
            Toast.error(title: "保存失败")
        }
    }
}

// MARK: - Line-numbered editor (UIKit)

/// A code editor: a `UITextView` with a fixed (non-scrolling) line-number gutter.
/// The gutter is a sibling view overlaid on the left; it redraws on scroll so numbers
/// stay aligned with the text while the content scrolls beneath.
struct LineNumberedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> EditorContainer {
        let container = EditorContainer()
        let textView = container.textView
        textView.delegate = context.coordinator
        textView.font = font
        textView.text = text
        // Put the caret at the start so UITextView never auto-scrolls to the end on load.
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.isEditable = isEditable
        context.coordinator.gutter = container.gutter
        JSSyntaxHighlighter.shared.highlight(textView)
        
        
        return container
    }

    func updateUIView(_ container: EditorContainer, context: Context) {
        let textView = container.textView
        var needsRedraw = false
        if textView.text != text {
            textView.text = text
            if !textView.userHasScrolled {
                textView.selectedRange = NSRange(location: 0, length: 0)
            }
            needsRedraw = true
            JSSyntaxHighlighter.shared.highlight(textView)
        }
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
            needsRedraw = true
        }
        if textView.font != font {
            textView.font = font
            needsRedraw = true
            JSSyntaxHighlighter.shared.highlight(textView)
        }
        if needsRedraw {
            textView.setNeedsLayout()
            container.gutter.setNeedsDisplay()
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: LineNumberedTextEditor
        weak var gutter: GutterView?
        private var highlightWork: DispatchWorkItem?

        init(parent: LineNumberedTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            gutter?.setNeedsDisplay()
            scheduleHighlight(textView)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            gutter?.setNeedsDisplay()
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            (scrollView as? CodeTextView)?.userHasScrolled = true
        }

        /// Debounced re-highlighting so rapid typing doesn't re-scan on every keystroke.
        private func scheduleHighlight(_ textView: UITextView) {
            highlightWork?.cancel()
            let work = DispatchWorkItem { [weak textView] in
                guard let textView else { return }
                JSSyntaxHighlighter.shared.highlight(textView)
            }
            highlightWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }
    }
}

/// UITextView that soft-wraps lines at 150 characters (or the view width on
/// narrow screens) with no horizontal scrolling.
final class CodeTextView: UITextView {
    fileprivate var userHasScrolled = false

    /// Soft-wrap cap, in monospaced characters.
    static let maxColumns: CGFloat = 150

    init() {
        let container = NSTextContainer()
        container.widthTracksTextView = false
        container.lineBreakMode = .byCharWrapping
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(container)
        let storage = NSTextStorage()
        storage.addLayoutManager(layoutManager)
        super.init(frame: .zero, textContainer: container)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func layoutSubviews() {
        let columnWidth = font?.estimatedCharacterWidth ?? 8.4
        let inset = textContainerInset
        let available = max(0, bounds.width - inset.left - inset.right)
        textContainer.size = CGSize(
            width: min(available, columnWidth * Self.maxColumns),
            height: 1_000_000
        )
        super.layoutSubviews()
        layoutManager.ensureLayout(for: textContainer)
        let used = layoutManager.usedRect(for: textContainer)
        let target = CGSize(
            width: bounds.width,
            height: max(bounds.height, used.height + inset.top + inset.bottom)
        )
        if abs(contentSize.width - target.width) > 0.5
            || abs(contentSize.height - target.height) > 0.5 {
            contentSize = target
        }
        pinToTop()
    }

    /// Pins the top of the document to the visible top until the user scrolls.
    func pinToTop() {
        guard !userHasScrolled, bounds.width > 0 else { return }
        let top = -contentInset.top
        if abs(contentOffset.y - top) > 0.5 {
            setContentOffset(CGPoint(x: 0, y: top), animated: false)
        }
    }
}

private extension UIFont {
    /// Average glyph width for this font, used to turn a column count into points.
    /// `m` is a safe upper bound for a monospaced font (where every glyph is equal
    /// anyway); using it leaves a tiny right margin rather than clipping.
    var estimatedCharacterWidth: CGFloat {
        ("m" as NSString).size(withAttributes: [.font: self]).width
    }
}

/// Holds the scrolling text view and the fixed gutter overlay.
final class EditorContainer: UIView {
    static let gutterWidth: CGFloat = 48

    let textView = CodeTextView()
    let gutter = GutterView()

    private var keyboardHeight: CGFloat = 0
    private var didScheduleInitialPin = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setup() {
        backgroundColor = .systemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(
            top: 8, left: Self.gutterWidth + 4, bottom: 8, right: 8
        )
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        // Hide the scroll indicators: their thumb position doesn't track the custom
        // contentInset/pinning reliably, and the editor has a fixed gutter + nav bar
        // context where an indicator adds noise rather than value.
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        // We own all insets (safe-area bars + keyboard). Automatic adjustment double-counts
        // with SwiftUI's keyboard avoidance and leaves a clipped bottom on dismiss.
        textView.contentInsetAdjustmentBehavior = .never
        addSubview(textView)

        gutter.translatesAutoresizingMaskIntoConstraints = false
        // Background is painted in draw() only below the top safe area, so lines numbers
        // (like the text) are hidden behind the navigation bar when scrolled.
        gutter.backgroundColor = .clear
        addSubview(gutter)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),

            gutter.topAnchor.constraint(equalTo: topAnchor),
            gutter.leadingAnchor.constraint(equalTo: leadingAnchor),
            gutter.bottomAnchor.constraint(equalTo: bottomAnchor),
            gutter.widthAnchor.constraint(equalToConstant: Self.gutterWidth),
        ])

        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func layoutSubviews() {
        gutter.textView = textView
        gutter.topInset = topInset
        // Apply insets before the text view lays out, so its top-pinning uses final insets.
        applyContentInset()
        super.layoutSubviews()
        // Re-assert the top pin after the subview layout pass: changing contentInset.top
        // makes iOS nudge contentOffset (and with it the scroll indicator) mid-track, so
        // the thumb ends up below the visible content top. Pinning again here keeps the
        // indicator flush with the top of the text.
        textView.pinToTop()
        gutter.setNeedsDisplay()
        scheduleInitialPinIfNeeded()
    }

    // MARK: Keyboard / insets

    /// The nav-bar overlap this editor sits under. Derived from the hosting view controller's
    /// safe area (the true overlap) rather than our own, which can disagree under `ignoresSafeArea`.
    private var topInset: CGFloat {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController.view.safeAreaInsets.top
            }
            responder = current.next
        }
        return window?.safeAreaInsets.top ?? 0
    }

    /// UITextView can re-apply a stale offset in a later layout pass, so re-assert the top pin
    /// once on the next runloop after the first laid-out pass.
    private func scheduleInitialPinIfNeeded() {
        guard !didScheduleInitialPin, textView.bounds.width > 0 else { return }
        didScheduleInitialPin = true
        DispatchQueue.main.async { [weak self] in
            self?.textView.pinToTop()
        }
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard
            let window,
            let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        // How much the keyboard overlaps *this* view.
        let endFrame = convert(frame, from: window.coordinateSpace)
        keyboardHeight = max(0, bounds.maxY - endFrame.minY)
        animateInsetChange(note)
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        keyboardHeight = 0
        animateInsetChange(note)
    }

    private func animateInsetChange(_ note: Notification) {
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)
            .flatMap { TimeInterval(exactly: $0) } ?? 0.25
        let rawCurve = (note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(rawCurve << 16))
        UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
            self?.applyContentInset()
            self?.layoutIfNeeded()
        }
    }

    /// Single source of truth for the text view's scrollable insets: top/bottom safe area + keyboard.
    private func applyContentInset() {
        let inset = UIEdgeInsets(
            top: topInset,
            left: 0,
            bottom: max(safeAreaInsets.bottom, keyboardHeight),
            right: 0
        )
        textView.contentInset = inset
        // Scroll indicators are hidden (see setup()), so no indicator insets needed.
        // Sync the scroll position immediately: when contentInset.top changes, iOS
        // auto-adjusts contentOffset to keep the *visual* content in place, which leaves
        // contentOffset.y at 0 instead of -inset.top — putting the scroll indicator
        // mid-track rather than at the top. Re-pin right away so thumb and text align.
        textView.pinToTop()
    }
}

/// Draws line numbers in the fixed gutter, aligned to the text view's current scroll offset.
final class GutterView: UIView {
    weak var textView: UITextView?
    var topInset: CGFloat = 0
    private let font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func draw(_ rect: CGRect) {
        guard let textView,
              let layoutManager = textView.layoutManager as NSLayoutManager?,
              let text = layoutManager.textStorage?.string else { return }
        let textContainer = textView.textContainer

        // The gutter's opaque area starts below the nav bar (topInset),
        // matching where the text is visible. Everything above stays clear / behind the bar.
        let drawRect = CGRect(
            x: 0, y: topInset, width: bounds.width, height: bounds.height - topInset
        )
        UIColor.systemBackground.setFill()
        UIRectFill(drawRect)

        // Faint separator on the gutter's right edge (only below the bar).
        UIColor.separator.setFill()
        UIRectFill(CGRect(x: bounds.maxX - 1, y: topInset, width: 1, height: drawRect.height))

        let offsetY = textView.contentOffset.y
        let inset = textView.textContainerInset
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        var lineNumber = 0
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.secondaryLabel,
        ]

        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) {
            [weak self] _, usedRect, _, lineGlyphRange, _ in
            guard let self else { return }
            // Number only at the start of each hard-wrapped paragraph (skip wrap continuations).
            let charRange = layoutManager.characterRange(
                forGlyphRange: lineGlyphRange, actualGlyphRange: nil
            )
            let startsParagraph: Bool
            if charRange.location == 0 {
                startsParagraph = true
            } else {
                let prev = text.index(before: String.Index(utf16Offset: charRange.location, in: text))
                let ch = text[prev]
                startsParagraph = ch == "\n" || ch == "\r"
            }
            guard startsParagraph else { return }

            lineNumber += 1

            // Convert into the gutter's fixed coordinate space (subtract scroll offset).
            let y = usedRect.minY - offsetY + inset.top
            // Cull lines outside the visible gutter — including anything scrolled up behind
            // the nav bar (above the top safe area), matching the text's clipping.
            guard y + usedRect.height >= topInset, y <= bounds.height else { return }

            let number = NSString(string: "\(lineNumber)")
            let size = number.size(withAttributes: attributes)
            number.draw(
                at: CGPoint(
                    x: bounds.width - size.width - 8,
                    y: y + (usedRect.height - size.height) / 2
                ),
                withAttributes: attributes
            )
        }
    }
}

// MARK: - JavaScript syntax highlighting

/// Lightweight JavaScript syntax highlighter (regex-based, zero dependencies).
/// Colors comments, strings, numbers, keywords and function calls. Colors adapt
/// to the current trait collection so dark/light both read well.
///
/// Highlighting writes directly to the text view's `textStorage` (it never
/// replaces `attributedText`), which keeps the caret position stable. Ranges
/// already colored by an earlier rule (e.g. a keyword inside a comment) are
/// skipped, so rule order encodes priority: comments/strings first.
@MainActor
final class JSSyntaxHighlighter {
    static let shared = JSSyntaxHighlighter()
    private init() {}

    // MARK: Colors (adaptive — clashing neon palette)

    private var defaultColor: UIColor { .label }
    private var keywordColor: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.36, blue: 1.0, alpha: 1)      // #FF5CFF hot magenta
                : UIColor(red: 0.84, green: 0.0, blue: 0.63, alpha: 1)     // #D600A0
        }
    }
    private var stringColor: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.0, green: 0.94, blue: 1.0, alpha: 1)      // #00F0FF electric cyan
                : UIColor(red: 0.0, green: 0.63, blue: 0.69, alpha: 1)     // #00A0B0
        }
    }
    private var commentColor: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.50, green: 1.0, blue: 0.0, alpha: 1)      // #7FFF00 lime green
                : UIColor(red: 0.29, green: 0.58, blue: 0.0, alpha: 1)     // #4A9500
        }
    }
    private var numberColor: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1)      // #FF8C00 vivid orange
                : UIColor(red: 0.80, green: 0.33, blue: 0.0, alpha: 1)     // #CC5500
        }
    }
    private var functionColor: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.90, blue: 0.0, alpha: 1)      // #FFE600 bright yellow
                : UIColor(red: 0.69, green: 0.53, blue: 0.0, alpha: 1)     // #B08800
        }
    }

    // MARK: Rules

    private struct Rule {
        let regex: NSRegularExpression
        let color: UIColor
    }

    private lazy var rules: [Rule] = {
        func rx(_ pattern: String) -> NSRegularExpression {
            try! NSRegularExpression(pattern: pattern, options: [])
        }
        let keywords = #"\b(?:var|let|const|function|return|if|else|for|while|do|switch|case|break|continue|class|extends|new|this|super|typeof|instanceof|in|of|import|export|from|default|try|catch|finally|throw|async|await|yield|static|get|set|null|undefined|true|false|void|delete)\b"#
        return [
            // Comments first so keywords inside them are skipped.
            Rule(regex: rx(#"/\*[\s\S]*?\*/"#), color: commentColor),                       // block comment
            Rule(regex: rx(#"//[^\n]*"#), color: commentColor),                              // line comment
            Rule(regex: rx(#""(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`(?:\\.|[^`\\])*`"#), color: stringColor),
            Rule(regex: rx(#"\b0[xX][0-9a-fA-F]+\b|\b\d[\d_]*\.?\d*(?:[eE][+-]?\d+)?\b"#), color: numberColor),
            Rule(regex: rx(keywords), color: keywordColor),
            Rule(regex: rx(#"\b[a-zA-Z_$][\w$]*(?=\s*\()"#), color: functionColor),         // function call
        ]
    }()

    // MARK: Apply

    /// Re-colors the entire text storage. Preserves the selection and the text
    /// view's font. Safe to call on the main thread during/after editing.
    func highlight(_ textView: UITextView) {
        let storage = textView.textStorage 
        let text = storage.string
        let length = (text as NSString).length
        guard length > 0 else { return }

        let resolvedFont = textView.font ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
        let selected = textView.selectedRange
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: resolvedFont,
            .foregroundColor: defaultColor,
        ]
        let whole = NSRange(location: 0, length: length)

        storage.beginEditing()
        storage.setAttributes(defaultAttrs, range: whole)

        var occupied: [NSRange] = []
        for rule in rules {
            rule.regex.enumerateMatches(in: text, options: [], range: whole) { result, _, _ in
                guard let result else { return }
                let r = result.range
                // Skip overlaps with already-colored regions (comments/strings win).
                if occupied.contains(where: { NSIntersectionRange(r, $0).length > 0 }) { return }
                storage.addAttributes([.foregroundColor: rule.color], range: r)
                occupied.append(r)
            }
        }
        storage.endEditing()

        // Some iOS versions reset the selection after setAttributes; restore it.
        if !NSEqualRanges(selected, textView.selectedRange) {
            textView.selectedRange = selected
        }
    }
}
