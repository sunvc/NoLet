//
//  ContentView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/3.
//

import Defaults
import GRDB
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass

    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared

    @Default(.firstStart) private var firstStart
    @Default(.showGroup) private var showGroup
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.usePtt) var usePtt


    @Namespace private var selectMessageSpace

    //  只能用 getValue: Binding 不然 16.0 不能pop
    private func _page(_ getValue: Binding<[RouterPage]>) -> Binding<[RouterPage]> {
        Binding { getValue.wrappedValue } set: {
            manager.router = $0
        }
    }

    @ViewBuilder
    private func tabLabel(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .symbolRenderingMode(.palette)
            .customForegroundStyle(.green, .primary)
    }

    var body: some View {
        ZStack {
            if sizeClass == .regular {
                NavigationSplitView(columnVisibility: $manager.homeViewMode) {
                    SettingsPage()
                } detail: {
                    NavigationStack(path: _page($manager.prouter)) {
                        MessagePage()
                            .router()
                    }
                }
                .onAppear {
                    manager.sizeClass = .regular
                }
            } else {
                compactHomeView()
                    .onAppear {
                        manager.sizeClass = .compact
                    }
            }
        }

        .sheet(isPresented: $firstStart) {
            PermissionsStartView {
                withAnimation { self.firstStart.toggle() }

                Task.detached(priority: .userInitiated) {
                    for item in await MessagesManager.examples() {
                        await MessagesManager.shared.add(item)
                    }
                }

                if Defaults[.cryptoConfigs].count == 0 {
                    Defaults[.cryptoConfigs] = [CryptoModelConfig.creteNewModel()]
                }
            }
            .customPresentationCornerRadius(30)
            .presentationDetents([.large])
            .interactiveDismissDisabled(true)
        }
        .sheet(item: Binding(get: { manager.sheetPage }, set: { manager.open(sheet: $0) })) {
            
            ContentSheetViewPage(value: $0)
        }
        .fullScreenCover(item: Binding(
            get: { manager.fullPage },
            set: { manager.open(full: $0) }
        )) {
            ContentFullViewPage(value: $0)
        }
        .diff { view in
            Group {
                if #available(iOS 18.0, *) {
                    view
                } else {
                    view
                        .fullScreenCover(item: $manager.selectMessage) { message in
                            SelectMessageView(message: message) {
                                withAnimation {
                                    manager.selectMessage = nil
                                }
                            }
                        }
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ContentSizeKey.self,
                    value: proxy.frame(in: .global).size
                )
            }
            .onPreferenceChange(ContentSizeKey.self) { value in
                manager.windowSize = value
            }
        )
    }

    @ViewBuilder
    func compactHomeView() -> some View {
        Group {
            if #available(iOS 26.0, *) {
                TabView(selection: updateTab) {
                    Tab(value: .message) {
                        NavigationStack(path: _page($manager.mrouter)) {
                            MessagePage().router()
                        }
                    } label: {
                        tabLabel(title: String(localized: "消息"), icon: "ellipsis.message")
                    }.badge(messageManager.unreadCount)

                    if usePtt {
                        Tab(value: .ptt) {
                            NavigationStack(path: _page($manager.trouter)) {
                                PTTContentView()
                                    .router()
                                    .toolbar(.hidden, for: .tabBar)
                            }
                        } label: {
                            tabLabel(title: String(localized: "语音"), icon: "message.and.waveform")
                        }
                    }

                    Tab(value: .setting) {
                        NavigationStack(path: _page($manager.srouter)) {
                            SettingsPage().router()
                        }
                    } label: {
                        tabLabel(title: String(localized: "设置"), icon: "gear.badge.questionmark")
                    }

                    if assistantAccouns.count > 0 {
                        Tab(value: .assistant, role: .search) {
                            NavigationStack(path: _page($manager.arouter)) {
                                NoLetChatHomeView().router()
                            }
                        } label: {
                            tabLabel(title: NCONFIG.AppName, icon: "apple.intelligence")
                        }
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)

            } else {
                TabView(selection: updateTab) {
                    NavigationStack(path: _page($manager.mrouter)) {
                        MessagePage().router()
                    }
                    .tabItem { tabLabel(title: String(localized: "消息"), icon: "ellipsis.message") }
                    .badge(messageManager.unreadCount)
                    .tag(TabPage.message)

                    if usePtt {
                        NavigationStack(path: _page($manager.trouter)) {
                            PTTContentView()
                                .router()
                                .toolbar(.hidden, for: .tabBar)
                        }
                        .tabItem { tabLabel(
                            title: String(localized: "语音"),
                            icon: "message.and.waveform"
                        ) }
                        .tag(TabPage.ptt)
                    }

                    NavigationStack(path: _page($manager.srouter)) {
                        SettingsPage().router()
                    }
                    .tabItem { tabLabel(
                        title: String(localized: "设置"),
                        icon: "gear.badge.questionmark"
                    ) }
                    .tag(TabPage.setting)

                    if assistantAccouns.count > 0 {
                        NavigationStack(path: _page($manager.arouter)) {
                            NoLetChatHomeView().router()
                        }
                        .tabItem {
                            tabLabel(title: NCONFIG.AppName, icon: "atom")
                        }
                        .tag(TabPage.assistant)
                    }
                }
            }
        }
    }

    private var updateTab: Binding<TabPage> {
        Binding {
            manager.page
        } set: { newTab in
            if newTab != manager.page {
                Task.detached {
                    await Haptic.impact()
                    await Tone.play(.share)
                }
            }

            if newTab == .assistant {
                manager.historyPage = manager.page
            }
            manager.page = newTab
        }
    }

    @ViewBuilder
    func ContentFullViewPage(value: SubPage) -> some View {
        Group {
            switch value {
            case .customKey:
                ChangeKeyView()
            case .scan:
                ScanView { code in
                    if AppManager.shared.HandlerOpenURL(url: code) == nil {
                        manager.open(full: nil)
                    }
                } track: { codes in
                    for code in codes {
                        let result = AppManager.shared.outParamsHandler(address: code)
                        if result != .text("") || result != .otherURL("") {
                            return code
                        }
                    }
                    return nil
                }
            case .web(let url):
                SFSafariView(url: url).ignoresSafeArea()
            default:
                EmptyView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        manager.open(full: nil)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func ContentSheetViewPage(value: SubPage) -> some View {
        Group {
            switch value {
            case .appIcon:
                AppIconView()
                    .presentationDetents([.height(350), .height(500)])
            case .cloudIcon:
                CloudIcon().presentationDetents([.medium, .large])
            case .paywall:
                if #available(iOS 18.0, *) { PayWallHighView() } else {
                    EmptyView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                manager.open(sheet: nil)
                                Haptic.impact()
                            }
                        }
                }
            case .quickResponseCode(let text, let title, let preview):
                QuickResponseCodeview(text: text, title: title, preview: preview)
                    .presentationDetents([.medium])
            case .crypto(let item):
                ChangeCryptoConfigView(item: item)
            case .share(let contents, let preview, let title):
                ActivityViewController(activityItems: contents, preview: preview, title: title)
                    .presentationDetents([.medium, .large])
            case .cloudServer:
                NavigationStack {
                    CloudServersView()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            case .authView:
                AuthTestView()
                    .presentationDetents([
                        ProcessInfo.processInfo.isiOSAppOnMac ? .height(600) : .medium,
                        .large,
                    ])
            default:
                EmptyView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        manager.open(sheet: nil)
                        Haptic.impact()
                    }
                }
            }
        }
        .customPresentationCornerRadius(30)
    }
}

extension View {
    func router() -> some View {
        navigationDestination(for: RouterPage.self) { router in
            Group {
                switch router {
                case .example:
                    MessageExampleView()

                case .messageDetail(let group):
                    MessageDetailView(group: group)
                        .navigationTitle(group)

                case .sound:
                    SoundView()

                case .noletChat:
                    NoLetChatHomeView()

                case .noletChatSetting(let account):
                    NoLetChatSettingsView(account: account)

                case .crypto:
                    CryptoConfigListView()

                case .server:
                    ServersConfigView()

                case .more:
                    MoreOperationsView()

                case .about:
                    AboutNoLetView()

                case .dataSetting:
                    DataSettingView()

                case .serverInfo(let server):
                    ServerMonitoringView(server: server)

                case .files(let url):
                    NoletFileList(rootURL: url)

                case .web(let url):
                    SFSafariView(url: url) {
                        AppManager.shared.router.removeLast()
                        Haptic.impact()
                    }
                    .ignoresSafeArea()
                    .navigationBarBackButtonHidden()

                case .appleServerInfo:
                    AppleStatusView()

                case .ptt:
                    PTTContentView()
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


struct ContentSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
}
