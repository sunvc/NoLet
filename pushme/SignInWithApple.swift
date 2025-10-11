//
//  SignInWithApple.swift
//  pushme
//
//  Created by lynn on 2025/8/23.
//

import SwiftUI
import AuthenticationServices
import Defaults

struct SignInWithApple: View {
    @Environment(\.colorScheme) var  colorScheme
    @Default(.id) var id
    @Default(.deviceToken) var deviceToken
    
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email]
        } onCompletion: { result in
            switch result {
            case .success(let authResults):
                handleAuthorization(authResults)
            case .failure(let error):
                NLog.error(error.localizedDescription)
                Toast.error(title: "Authorization failed")
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .black : .white)
        .frame( height: 50, alignment: .center)
    }
    
    private func handleAuthorization(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            let user = appleIDCredential.user
            let email = appleIDCredential.email
            
            // 保存用户ID，用作后续登录识别
            self.id = user
            
            Task.detached(priority: .userInitiated){
                if let user = await CloudManager.shared.queryUser(user, email: email){
                    NLog.error(user)
                }
            }
        }
    }
}
