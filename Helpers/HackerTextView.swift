//
//  HackerTextView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/2.
//

import SwiftUI

struct HackerTextView: View {
    /// Config
    var text: String
    var trigger: Bool
    var transition: ContentTransition = .interpolate
    var duration: CGFloat = 1.0
    var speed: CGFloat = 0.1
    /// View Properties
    @State private var animatedText: String = ""
    @State private var randomCharacters: [Character] =
        Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUWVXYZ0123456789-?/#$%@!^&*()=")

    @State private var animationTask: Task<Void, Never>? = nil

    var body: some View {
        Text(verbatim: animatedText)
            .monospaced()
            .truncationMode(.tail)
            .contentTransition(transition)
            .animation(.easeInOut(duration: 0.15), value: animatedText)
            .onAppear {
                guard animatedText.isEmpty else { return }
                setRandomCharacters()
                animateText()
            }
            .onChange(of: trigger) { _ in
                animatedText = text
                setRandomCharacters()
                animateText()
            }
            .onDisappear {
                animationTask?.cancel()
            }
    }

    private func animateText() {
        animationTask?.cancel()
        let count = text.count
        let delays = (0..<count).map { _ in CGFloat.random(in: 0...duration) }
        var elapsed = Array(repeating: CGFloat(0), count: count)
        var settled = Array(repeating: false, count: count)
        let randomChars = randomCharacters
        let sleepNs = UInt64(max(speed, 0.01) * 1_000_000_000)
        animationTask = Task {
            var finished = 0
            while !Task.isCancelled && finished < count {
                try? await Task.sleep(nanoseconds: sleepNs)
                await MainActor.run {
                    for i in 0..<count {
                        if settled[i] { continue }
                        elapsed[i] += speed
                        let idxAnimated = animatedText.index(animatedText.startIndex, offsetBy: i)
                        if elapsed[i] >= delays[i] {
                            let idxText = text.index(text.startIndex, offsetBy: i)
                            let actualCharacter = text[idxText]
                            replaceCharacter(at: idxAnimated, character: actualCharacter)
                            settled[i] = true
                            finished += 1
                        } else {
                            if let rc = randomChars.randomElement() {
                                replaceCharacter(at: idxAnimated, character: rc)
                            }
                        }
                    }
                }
            }
        }
    }

    private func setRandomCharacters() {
        animatedText = text
        for index in animatedText.indices {
            guard let randomCharacter = randomCharacters.randomElement() else { return }
            replaceCharacter(at: index, character: randomCharacter)
        }
    }

    /// Changes Character at the given index
    func replaceCharacter(at index: String.Index, character: Character) {
        guard animatedText.indices.contains(index) else { return }
        let indexCharacter = String(animatedText[index])

        if indexCharacter.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            animatedText.replaceSubrange(index...index, with: String(character))
        }
    }
}

#Preview {
    HackerTextView(
        text: "123asda1ag",
        trigger: true,
        transition: .numericText(),
        speed: 0.05
    )
}
