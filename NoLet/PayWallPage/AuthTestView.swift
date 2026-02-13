//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AuthTestView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/2/12 21:16.

import AuthenticationServices
import SwiftUI

struct AuthTestView: View {
    var body: some View {
        NavigationStack { 
            List {
                HStack{
                    Spacer()
                    Image("launch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                    
                SignInWithApple()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                    .padding(.vertical)

                Button {
                    if ProcessInfo.processInfo.isiOSAppOnMac {
                        Task {
                            await WeChatManager.shared.qrCode()
                        }
                    } else {
                        WeChatManager.auth()
                    }

                } label: {
                    HStack {
                        Image("wechat")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35)
                        if ProcessInfo.processInfo.isiOSAppOnMac {
                            Text("微信扫码登录")
                        } else {
                            Text("微信授权登陆")
                        }
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
                    .background(.background)
                    .clipShape(.rect)
                }
                
                .buttonStyle(.borderless)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
            }
            .navigationTitle("账号中心(Test)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
