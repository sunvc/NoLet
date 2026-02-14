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
    @Default(.showGroup) private var showGroup
    @StateObject private var manager = AppManager.shared
    @StateObject private var messageManager = MessagesManager.shared
    @Default(.firstStart) private var firstStart
    @Default(.assistantAccouns) var assistantAccouns

    @State private var HomeViewMode: NavigationSplitViewVisibility = .detailOnly

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
                NavigationSplitView(columnVisibility: $HomeViewMode) {
                    SettingsPage()
                        .environmentObject(manager)
                } detail: {
                    NavigationStack(path: _page($manager.prouter)) {
                        MessagePage()
                            .router(manager)
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
        .environmentObject(manager)
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
                    key: ContentWidthKey.self,
                    value: proxy.frame(in: .global).width
                )
            }
            .onPreferenceChange(ContentWidthKey.self) { value in
                manager.totalWidth = value
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
                            MessagePage().router(manager)
                        }
                    } label: {
                        tabLabel(title: String(localized: "消息"), icon: "ellipsis.message")
                    }.badge(messageManager.unreadCount)

                    Tab(value: .setting) {
                        NavigationStack(path: _page($manager.srouter)) {
                            SettingsPage().router(manager)
                        }
                    } label: {
                        tabLabel(title: String(localized: "设置"), icon: "gear.badge.questionmark")
                    }

                    if assistantAccouns.count > 0 {
                        Tab(value: .assistant, role: .search) {
                            NavigationStack(path: _page($manager.arouter)) {
                                NoLetChatHomeView().router(manager)
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
                        MessagePage().router(manager)
                    }
                    .tabItem { tabLabel(title: String(localized: "消息"), icon: "ellipsis.message") }
                    .badge(messageManager.unreadCount)
                    .tag(TabPage.message)

                    NavigationStack(path: _page($manager.srouter)) {
                        SettingsPage().router(manager)
                    }
                    .tabItem { tabLabel(
                        title: String(localized: "设置"),
                        icon: "gear.badge.questionmark"
                    ) }
                    .tag(TabPage.setting)

                    if assistantAccouns.count > 0 {
                        NavigationStack(path: _page($manager.arouter)) {
                            NoLetChatHomeView().router(manager)
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
        .environmentObject(manager)
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
                        .environmentObject(manager)
                        .environmentObject(NoLetChatManager.shared)
                }
            case .authView:
                AuthTestView()
                    .presentationDetents([ProcessInfo.processInfo.isiOSAppOnMac ? .height(600) : .medium, .large])
            default:
                EmptyView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        manager.open(sheet: nil)
                        Haptic.impact()
                    }
                }
            }
        }
        .environmentObject(manager)
        .customPresentationCornerRadius(30)
    }
}

extension View {
    func router(_ manager: AppManager) -> some View {
        navigationDestination(for: RouterPage.self) { router in
            Group {
                switch router {
                case .example:
                    ExampleView()

                case .messageDetail(let group):
                    MessageDetailPage(group: group)
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
                        manager.router.removeLast()
                        Haptic.impact()
                    }
                    .ignoresSafeArea()
                    .navigationBarBackButtonHidden()

                case .appleServerInfo:
                    AppleStatusView()
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarTitleDisplayMode(.large)
            .environmentObject(manager)
        }
    }
}

struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
