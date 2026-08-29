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
import CoreData
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass

    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared
    @ObservedObject private var audioManager = AudioManager.shared
    @ObservedObject private var database = DatabaseManager.shared

    @Default(.firstStart) private var firstStart
    @Default(.showGroup) private var showGroup
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.usePtt) var usePtt

    @Namespace private var selectMessageSpace

    // FIXME: - 只能用 getValue: Binding 不然 16.0 不能pop
    private func _page(_ getValue: Binding<[RouterPage]>) -> Binding<[RouterPage]> {
        Binding { getValue.wrappedValue } set: { manager.router = $0 }
    }

    @ViewBuilder
    private func tabLabel(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .symbolRenderingMode(.palette)
            .customForegroundStyle(.green, .primary)
    }

    var body: some View {
        ZStack {
            if database.needsRestart {
                DatabaseRestartView()
            } else if let error = database.storeLoadError {
                DatabaseRecoveryView(
                    error: error,
                    isResetting: database.isResetting,
                    onReset: {
                        Task {
                            do {
                                try await database.resetStore()
                            } catch {
                                Toast.shared.present(
                                    title: String(localized: "重置失败，请删除应用后重装"),
                                    symbol: "xmark.octagon"
                                )
                            }
                        }
                    }
                )
            } else if sizeClass == .regular {
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

                Task { @MainActor in
                    for item in MessagesManager.examples() {
                        await MessagesManager.shared.add(item)
                    }
                }

                if Defaults[.cryptoConfigs].count == 0 {
                    Defaults[.cryptoConfigs] = [CryptoModelConfig.creteNewModel()]
                }
            }
            .customPresentationCornerRadius(30)
            .customDetents([.large])
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
        .safeAreaInset(edge: .bottom) {
            if audioManager.speaking {
                Rectangle()
                    .fill(.clear)
                    .glassCard()
                    .overlay {
                        MusicInfo()
                    }

                    .frame(height: 70)
                    .overlay(alignment: .bottom, content: {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 1)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .offset(y: manager.router.count == 0 ? -49 : 0)
                    .transition(.move(edge: .trailing).animation(.easeInOut(duration: 0.2)))
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ContentSizeKey.self,
                    value: proxy.frame(in: .global).size
                )
            }
            .onPreferenceChange(ContentSizeKey.self) {
                manager.windowSize = $0
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIDevice.orientationDidChangeNotification
            )) { _ in
                if let orientation = UIApplication.shared.interfaceOrientation {
                    AppManager.shared.orientation = orientation
                }
            }
        )
        .overlay {
            if messageManager.isDeleting {
                DeletingOverlay()
            }
        }
        .environment(\.managedObjectContext, DatabaseManager.shared.viewContext)
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
                            tabLabel(title: String(localized: "对讲"), icon: "message.and.waveform")
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
                                    .toolbar(
                                        manager.page == .assistant ? .hidden : .visible,
                                        for: .tabBar
                                    )
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
                            title: String(localized: "对讲"),
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
                                .toolbar(
                                    manager.page == .assistant ? .hidden : .visible,
                                    for: .tabBar
                                )
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

            if newTab == .assistant || newTab == .ptt {
                manager.historyPage = manager.page
            }
            withAnimation(.spring(
                response: 0.3,
                dampingFraction: 0.5,
                blendDuration: 0
            )) {
                manager.page = newTab
            }
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
                SFSafariView(url: url)
                    .ignoresSafeArea()
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
                    .customDetents([.height(350), .height(500)])
            case .cloudIcon:
                CloudIcon().customDetents([.medium, .large])
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
                    .customDetents([.medium])
            case .crypto(let item):
                ChangeCryptoConfigView(item: item)
            case .share(let contents, let preview, let title):
                ActivityViewController(activityItems: contents, preview: preview, title: title)
                    .customDetents([.medium, .large])
            case .cloudServer:
                NavigationStack {
                    CloudServersView()
                        .customDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            case .authView:
                AuthTestView()
                    .customDetents([.medium, .large])
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
        .diff { view in
            Group {
                if #available(iOS 18.0, *) {
                    view.presentationSizing(.page)
                } else {
                    view
                }
            }
        }
    }
}

extension View {
    fileprivate func router() -> some View {
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
                    ServersManagementView()

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
                        if AppManager.shared.router.count > 0 {
                            AppManager.shared.router.removeLast()
                        }
                        Haptic.impact()
                    }
                    .ignoresSafeArea()
                    .toolbar(.hidden, for: .navigationBar)

                case .appleServerInfo:
                    AppleStatusView()

                case .ptt:
                    PTTContentView()

                case .script:
                    ScriptsView()

                case .notificationActions:
                    NotificationActionsView()
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ContentSizeKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension UIApplication {
    fileprivate var interfaceOrientation: UIInterfaceOrientation? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation
    }
}

private struct DeletingOverlay: View {
    @State private var progress: Double = 0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("正在删除消息...")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                ProgressView(value: progress, total: 100)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(width: 180)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
        .allowsHitTesting(true)
        .onReceive(timer) { _ in
            guard progress < 80 else { return }
            progress = min(80, progress + Double.random(in: 0.8...2.4))
        }
    }
}

/// 数据库重置成功后提示用户退出重开。重置过程中旧的 NSManagedObject 全部失效，
/// 继续运行可能触发 fault 异常，必须重启进程才能安全使用。
private struct DatabaseRestartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(.green)

            Text("数据库已重置")
                .font(.title2.bold())

            Text("数据库已重建完成。需要退出应用后重新打开才能继续使用。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    exit(0)
                }
            } label: {
                Label("退出应用", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

/// 数据库存储加载失败（通常是文件损坏）时显示的恢复页，替代直接崩溃。
private struct DatabaseRecoveryView: View {
    let error: String
    let isResetting: Bool
    let onReset: () -> Void

    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "externaldrive.trianglebadge.exclamationmark")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(.orange)

            Text("数据库无法打开")
                .font(.title2.bold())

            Text("本地消息数据库已损坏，应用无法继续使用。重置前会自动备份当前数据库（保留最近 5 份），但备份无法在应用内恢复，仅供数据排查。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if !error.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(4)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(role: .destructive) {
                showConfirm = true
            } label: {
                Group {
                    if isResetting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("重置数据库", systemImage: "arrow.counterclockwise")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isResetting)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .confirmationDialog(
                "确定要重置数据库吗？所有本地消息将被永久删除，无法恢复。",
                isPresented: $showConfirm,
                titleVisibility: .visible
            ) {
                Button("重置并清空所有数据", role: .destructive) {
                    onReset()
                }
                Button("取消", role: .cancel) {}
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
