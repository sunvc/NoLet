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
    @StateObject private var wechat = WeChatManager.shared
    var body: some View {
        NavigationStack {
            VStack {
                if let image = wechat.QRCodeImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .transition(.scale)
                        .padding()

                } else {
                    Image("launch")
                        .resizable()
                        .scaledToFit()
                        .transition(.scale)
                        .padding()
                }

                if wechat.QRCodeImage == nil {
                    VStack{
                        Spacer()
                        SignInWithApple()
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
                                if wechat.QRCodeLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                    Text("正在获取二维码")
                                } else {
                                    Image("wechat")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 26)
                                    if ProcessInfo.processInfo.isiOSAppOnMac {
                                        Text("微信扫码登录")
                                    } else {
                                        Text("微信授权登陆")
                                    }
                                }
                            }
                            .font(.title3)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(.background)
                            .clipShape(.rect)
                        }
                        .disabled(wechat.QRCodeLoading)
                        .buttonStyle(.borderless)
                        .padding(.bottom, 50)
                    }.padding(.horizontal)
                }
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("账号中心(Test)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if wechat.QRCodeImage != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            wechat.QRCodeImage = nil
                        } label: {
                            Label("关闭", systemImage: "arrow.uturn.backward.circle")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AuthTestView()
}
