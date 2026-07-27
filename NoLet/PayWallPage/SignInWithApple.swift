//
//  SignInWithApple.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/8/23.
//

import AuthenticationServices
import Defaults
import SwiftUI

struct SignInWithApple: View {
    @Environment(\.colorScheme) var colorScheme
    @Default(.member) var member

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email]
        } onCompletion: { result in
            switch result {
            case .success(let authResults):
                handleAuthorization(authResults)
            case .failure(let error):
                logger.error("\(error)")
                Toast.shared.present(title: "Authorization failed", symbol: .error)
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .black : .white)
        .frame(height: 50, alignment: .center)
    }

    private func handleAuthorization(_ authResults: ASAuthorization) {
    }
}
