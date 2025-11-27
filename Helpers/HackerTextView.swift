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
    @State private var randomCharacters: [Character] = {
        let string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUWVXYZ0123456789-?/#$%@!^&*()="
        return Array(string)
    }()

    @State private var animationID: String = UUID().uuidString

    var body: some View {
        Text(animatedText)
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
                animateText()
            }
            .onChange(of: trigger) { _ in
                animatedText = text
                animationID = UUID().uuidString
                setRandomCharacters()
                animateText()
            }
    }

    private func animateText() {
        let currentID = animationID
        for index in text.indices {
            let delay = CGFloat.random(in: 0...duration)
            var timerDuration: CGFloat = 0

            let timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
                if currentID != animationID {
                    timer.invalidate()
                } else {
                    timerDuration += speed
                    if timerDuration >= delay {
                        if text.indices.contains(index) {
                            let actualCharacter = text[index]
                            replaceCharacter(at: index, character: actualCharacter)
                        }

                        timer.invalidate()
                    } else {
                        guard let randomCharacter = randomCharacters.randomElement() else { return }
                        replaceCharacter(at: index, character: randomCharacter)
                    }
                }
            }

            timer.fire()
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
    if #available(iOS 16.1, *) {
        HackerTextView(
            text: "123",
            trigger: true,
            transition: .numericText(),
            speed: 0.05
        )

    } else {
        // Fallback on earlier versions
    }
}
