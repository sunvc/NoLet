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

    @Default(.showGroup) private var showGroup
    @StateObject private var manager = AppManager.shared
    @StateObject private var messageManager = MessagesManager.shared
    @Default(.firstStart) private var firstStart
    @Default(.assistantAccouns) var assistantAccouns

    @State private var HomeViewMode: NavigationSplitViewVisibility = .detailOnly

    @Namespace private var selectMessageSpace

    var body: some View {
        ZStack {
            if .ISPAD {
                IpadHomeView()
            } else {
                IphoneHomeView()
            }

            if firstStart {
                firstStartLauchFirstStartView()
            }
        }
        .environmentObject(manager)
        .overlay {
            if manager.isLoading && manager.inAssistant {
                ColoredBorder()
            }
        }
        .sheet(isPresented: manager.sheetShow) { ContentSheetViewPage() }
        .fullScreenCover(isPresented: manager.fullShow) { ContentFullViewPage() }
    }

    @ViewBuilder
    func IphoneHomeView() -> some View {
        Group {
            if #available(iOS 26.0, *) {
                TabView(selection: Binding(get: { manager.page }, set: { updateTab(with: $0) })) {
                    Tab(value: .message) {
                        NavigationStack(path: Binding(get: {
                            manager.mrouter
                        }, set: { value in
                            manager.router = value
                        })) {
                            // MARK: 信息页面

                            MessagePage()
                                .router(manager)
                        }
                    } label: {
                        Label("消息", systemImage: "ellipsis.message")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }.badge(messageManager.unreadCount)
                    
                    if assistantAccouns.count > 0 {
                        Tab(value: .assistant) {
                            NavigationStack(path: Binding(get: {
                                manager.arouter
                            }, set: { value in
                                manager.router = value
                            })) {
                               
                                // MARK: 信息页面

                                AssistantPageView()
                                    .router(manager)
                            }
                        } label: {
                            Label("无字书", systemImage: "apple.intelligence")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.green, .primary)
                        }
                    }
                    
                    

                    Tab(value: .setting) {
                        NavigationStack(path: Binding(get: {
                            manager.srouter
                        }, set: { value in
                            manager.router = value
                        })) {
                            // MARK: 设置页面

                            SettingsPage()
                                .router(manager)
                        }
                    } label: {
                        Label("设置", systemImage: "gear.badge.questionmark")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }

                    Tab(value: .search, role: .search) {
                        NavigationStack(path: Binding(get: {
                            manager.sorouter
                        }, set: { value in
                            manager.router = value
                        })) {
                            // MARK: 设置页面

                            SearchMessageView()
                                .router(manager)
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }

                }.tabBarMinimizeBehavior(.onScrollDown)
            } else {
                TabView(selection: Binding(get: { manager.page }, set: { updateTab(with: $0) })) {
                    NavigationStack(path: Binding(get: {
                        manager.mrouter
                    }, set: { value in
                        manager.router = value
                    })) {
                        // MARK: 信息页面

                        MessagePage()
                            .router(manager)
                    }
                    .tabItem {
                        Label("消息", systemImage: "ellipsis.message")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }
                    .badge(messageManager.unreadCount)
                    .tag(TabPage.message)
                    
                    if assistantAccouns.count > 0{
                        NavigationStack(path: Binding(get: {
                            manager.arouter
                        }, set: { value in
                            manager.router = value
                        })) {
                           
                            // MARK: 信息页面

                            AssistantPageView()
                                .router(manager)
                        }
                        .tabItem {
                            Label("无字书", systemImage: "apple.intelligence")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.green, .primary)
                        }
                        .tag(TabPage.assistant)
                    }
                    
                    NavigationStack(path: Binding(get: {
                        manager.srouter
                    }, set: { value in
                        manager.router = value
                    })) {
                        // MARK: 设置页面

                        SettingsPage()
                            .router(manager)
                    }
                    .tabItem {
                        Label("设置", systemImage: "atom")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }
                    .tag(TabPage.setting)
                }
            }
        }
    }

    func updateTab(with newTab: TabPage) {
        Haptic.impact()
        AudioManager.tips(.share)
        manager.page = newTab
    }

    @ViewBuilder
    func IpadHomeView() -> some View {
        NavigationSplitView(columnVisibility: $HomeViewMode) {
            SettingsPage()
                .environmentObject(manager)
        } detail: {
            NavigationStack(path: Binding(get: {
                manager.prouter
            }, set: { value in
                manager.router = value
            })) {
                MessagePage()
                    .router(manager)
            }
        }
    }

    @ViewBuilder
    func firstStartLauchFirstStartView() -> some View {
        PermissionsStartView {
            withAnimation { self.firstStart.toggle() }

            Task.detached(priority: .userInitiated) {
                for item in MessagesManager.examples() {
                    await MessagesManager.shared.add(item)
                }
            }

            if Defaults[.cryptoConfigs].count == 0 {
                Defaults[.cryptoConfigs] = [CryptoModelConfig.creteNewModel()]
            }
        }
        .background26(.ultraThinMaterial, radius: 5)
    }

    @ViewBuilder
    func ContentFullViewPage() -> some View {
        Group {
            switch manager.fullPage {
            case .customKey:
                ChangeKeyView()
            case .scan:
                ScanView { code in
                    if AppManager.shared.HandlerOpenURL(url: code) == nil {
                        manager.fullPage = .none
                    }
                }
            case .web(let url):
                SFSafariView(url: url).ignoresSafeArea()
            case .nearby:
                NearbyNoLetView()
            default:
                EmptyView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        manager.fullPage = .none
                    }
                }
            }
        }
        .environmentObject(manager)
    }

    @ViewBuilder
    func ContentSheetViewPage() -> some View {
        Group {
            switch manager.sheetPage {
            case .appIcon:
                NavigationStack {
                    AppIconView()
                }.presentationDetents([.height(300)])
            case .cloudIcon:
                CloudIcon().presentationDetents([.medium, .large])
            case .paywall:
                if #available(iOS 18.0, *) { PayWallHighView() } else {
                    EmptyView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                manager.sheetPage = .none
                                Haptic.impact()
                            }
                        }
                }
            case .quickResponseCode(let text, let title, let preview):
                QuickResponseCodeview(text: text, title: title, preview: preview)
                    .presentationDetents([.medium])
            case .crypto(let item):
                ChangeCryptoConfigView(item: item)
            case .share(let contents):
                ActivityViewController(activityItems: contents)
                    .presentationDetents([.medium, .large])
            default:
                EmptyView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        manager.sheetPage = .none
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

                case .assistant:
                    AssistantPageView()

                case .assistantSetting(let account):
                    AssistantSettingsView(account: account)

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
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarTitleDisplayMode(.large)
            .environmentObject(manager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
