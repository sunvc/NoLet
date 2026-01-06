//
//  AboutNoLetView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import Defaults
import StoreKit
import SwiftUI

struct AboutNoLetView: View {
    @EnvironmentObject private var manager: AppManager
    @Default(.appIcon) private var setting_active_app_icon
    @Default(.deviceToken) private var deviceToken
    @Default(.id) private var id
    @Default(.nearbyShow) private var nearbyShow

    @State private var showNearbySetting: Bool = false
    @State private var buildDetail: Bool = false
    @State private var product: Product?
    @State private var purchaseResult: Product.PurchaseResult?
    var buildVersion: String {
        // 版本号
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        // build号
        var buildNumber: String {
            if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
               let versionNumber = Int(version)
            {
                return String(versionNumber, radix: 16).uppercased()
            }
            return ""
        }

        return buildDetail ? "\(appVersion)(\(buildNumber))" : appVersion
    }

    var body: some View {
        List {
            // Logo 部分
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(setting_active_app_icon.logo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .accessibilityLabel("点击切换应用图标")
                            .onTapGesture {
                                manager.open(sheet: .appIcon)
                                Haptic.impact()
                            }
                            .onLongPressGesture {
                                if nearbyShow {
                                    manager.open(full: .nearby)
                                } else {
                                    self.showNearbySetting.toggle()
                                }
                                Haptic.impact()
                            }

                        Text(NCONFIG.AppName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("版本 \(buildVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .onTapGesture {
                                buildDetail.toggle()
                                Haptic.impact()
                            }
                            .accessibilityLabel("版本 \(buildVersion)，双击切换显示")
                    }
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // 应用信息部分
            Section {
                ListButton(leading: {
                    Label {
                        Text(verbatim: "TOKEN")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "captions.bubble")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.primary, .accent)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(deviceToken), trigger: false)
                        .foregroundStyle(.gray)

                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, Color.primary)

                }, showRight: false) {
                    if deviceToken != "" {
                        Clipboard.set(deviceToken)
                        Toast.copy(title: "复制成功")

                    } else {
                        Toast.question(title: "请先注册")
                    }
                    return true
                }

                ListButton(leading: {
                    Label {
                        Text(verbatim: "ID")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "person.badge.key")

                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(Color.primary, .accent)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(id), trigger: false)
                        .foregroundStyle(.gray)

                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, Color.primary)

                }, showRight: false) {
                    Clipboard.set(id)
                    Toast.copy(title: "复制成功")
                    return true
                }
                if showNearbySetting || nearbyShow {
                    Toggle(isOn: $nearbyShow) {
                        Label("附近的书", systemImage: "location.viewfinder")
                    }
                }

                // App开源地址
                ListButton {
                    Label {
                        Text("使用文档")
                    } icon: {
                        Image(systemName: "questionmark.app.dashed")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.blue, Color.primary)
                    }
                } action: {
                    manager.router.append(.web(url: NCONFIG.docServer.url))
                    return true
                }

                // App开源地址
                ListButton {
                    Label {
                        Text("App开源地址")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "iphone.homebutton.circle")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.blue, Color.primary)
                    }
                } action: {
                    manager.router.append(.web(url: NCONFIG.appSource.url))
                    return true
                }

                // 服务器开源地址
                ListButton {
                    Label {
                        Text("服务器开源地址")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "lock.open.desktopcomputer")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, Color.primary)
                    }
                } action: {
                    manager.router.append(.web(url: NCONFIG.serverSource.url))
                    return true
                }

            } header: {
                Text("应用信息")
                    .textCase(.none)
            }

            Section {
                VStack {
                    HStack(spacing: 10) {
                        Spacer()

                        Button {
                            manager.router.append(.web(url: NCONFIG.privacyURL.url))
                            Haptic.impact()

                        } label: {
                            Text("隐私政策")
                        }.buttonStyle(.borderless)
                        Circle()
                            .frame(width: 3, height: 3)

                        Button {
                            manager.router.append(.web(url: NCONFIG.userAgreement.url))
                            Haptic.impact()

                        } label: {
                            Text("用户协议")
                        }.buttonStyle(.borderless)

                        Spacer()
                    }
                    .font(.caption)

                    HStack {
                        Spacer()
                        Text(verbatim: "© 2024 WZS All rights reserved.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                        Spacer()
                    }.padding(.top)
                }
            }.listRowBackground(Color.clear)
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .largeTitle) {
                    Text(verbatim: "")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    requestReview()
                    Haptic.impact()
                } label: {
                    Label("去评分", systemImage: "star.bubble")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.yellow, Color.primary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProduct()
        }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: ["one_time_support_2_99"])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) + str }
        return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(4)
    }
}

extension NCONFIG {
    private static let wikiServer: NURL = "https://wiki.wzs.app"

    static let delpoydoc: NURL = docServer + "deploy"
    static let privacyURL: NURL = docServer + "policy"
    static let tutorialURL: NURL = docServer + "tutorial"
    static let encryURL: NURL = docServer + "encryption"
    static let pushHelp: NURL = docServer + "tutorial"

    static var docServer: NURL {
        wikiServer + String(localized: "NoletLanguageLocalCode")
    }
}

#Preview {
    ContentView()
}
