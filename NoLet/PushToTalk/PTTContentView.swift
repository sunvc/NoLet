//
//  PushToTalkView.swift
//  NoLet
//
//  Created by lynn on 2025/7/18.
//

import AVFAudio
import Combine
import Defaults
import SwiftUI
import MapKit

struct PTTContentView: View {
    @State private var ispress: Bool = false

    @ObservedObject private var pttManager = PTTManager.shared

    @State private var buttonType: TalkButtonType = .call

    @State private var historyNumber: Int = 0

    @State private var mhzTem: Int = -1
    @State private var khzTem: Int = -1
    @State private var showSettings: Bool = false

    @Default(.pttChannel) var pttChannel
    @Default(.pttVibration) var pttVibration
    @Default(.pttMusicPlay) var pttMusicPlay
    @Default(.servers) var servers
    @Default(.pttHisChannel) var pttHisChannel
    @Default(.pttVoiceVolume) var pttVoiceVolume
    @Default(.pttSignature) var pttSignature

    @State private var isCancel: Bool = false

    @State private var showChannelList: Bool = false
    @State private var showVoiceList: Bool = false

    @State private var offset: CGFloat = 0

    @State private var isEncryption: Bool = true

    @State private var newMessages: Int = 0

    @State private var showVolume: Bool = false
    @State private var hideWorkItem: DispatchWorkItem?

    @State private var isButtonPressed = false
    @State private var dragOffset: CGFloat = 0.0
    private let maxDragDistance: CGFloat = 130.0

    @State private var showUserMapTem: Bool = false
    @State private var logoDragStartRegion: MKCoordinateRegion?

    @State private var showBackup: Bool = false

    var showUserMap: Bool {
        return pttManager.powerState && showUserMapTem
    }

    var currentProgress: Double {
        switch pttManager.state {
        case .idle, .preparingPlay, .interrupted, .interruptionEnded:
            return 0
        case .playing:
            return pttManager.currentPlayTime / max(pttManager.totalPlayTime, 1)
        case .recording:
            return pttManager.micLevel
        }
    }

    var buttonColor: Color {
        if isCancel {
            return ispress ? .red : .clear
        } else {
            if ispress {
                return pttManager.state == .recording ? .green : .orange
            }
            return .clear
        }
    }

    var isPlaying: Bool {
        if case .playing = pttManager.state { true } else { false }
    }

    var isRecording: Bool {
        if case .recording = pttManager.state { true } else { false }
    }

    var networkIcon: (String, Color, Color) {
        if !pttManager.powerState {
            return ("network.slash", .red, .primary)
        }
        switch pttManager.serverStatus {
        case .offline:
            return ("network", .red, .red)
        case .connecting:
            return ("antenna.radiowaves.left.and.right", .blue, .primary)
        case .online:
            return pttSignature ?
                ("network.badge.shield.half.filled", .blue, .primary) :
                ("network", .primary, .red)
        case .failed:
            return (pttSignature ? "network.badge.shield.half.filled" : "network", .red, .red)
        }
    }

    var stateTitle: String {
        // 1. 特殊前置状态：未启动监听
        if !pttManager.powerState && !isPlaying {
            return String(localized: "未启动监听")
        }

        // 2. 场景 A：当没显示用户地图时
        if !self.showUserMap {
            if pttManager.serverStatus == .failed && pttManager.state == .idle {
                return String(localized: "服务器未连接")
            }
            return pttManager.state.title
        }

        // 3. 场景 B：当显示了用户地图时（只在播放或录制时显示 title，其余隐形）
        if isPlaying || isRecording {
            return pttManager.state.title
        }

        return ""
    }

    var iconVolume: String {
        if pttVoiceVolume <= 0 {
            return "speaker.fill"
        } else if pttVoiceVolume < 0.4 {
            return "speaker.wave.1.fill"
        } else if pttVoiceVolume < 0.7 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    @State private var isAnimatingHint = false

    @State private var showTips = false

    var body: some View {
        VStack {
            ZStack {
                GreenbackgroundView()

                VStack {
                    HStack {
                        if AppManager.shared.sizeClass != .regular {
                            HourAndMinuteView()
                                .font(.numberStyle(size: 27))
                        }

                        Spacer()

                        HStack(spacing: 15) {
                            Image(systemName: networkIcon.0)
                                .fontWeight(.bold)
                                .scaleEffect(1.2)
                                .foregroundStyle(networkIcon.1, networkIcon.2)
                                .onTapGesture {
                                    if pttManager.powerState && pttManager.serverStatus == .failed {
                                        Task {
                                            try await pttManager.joinConnect()
                                        }
                                    }
                                }

                            ZStack {
                                Image(systemName: "tray.and.arrow.up")
                                    .foregroundStyle(.red, .white)
                                    .opacity(isRecording ? 1 : 0)
                                    .scaleEffect(1.3)
                                    .offset(y: -3)

                                var showTray: Bool {
                                    pttManager.state == .idle && newMessages <= 0
                                }
                                Image(systemName: "tray")
                                    .foregroundStyle(.white)
                                    .opacity(showTray ? 1 : 0)
                                    .scaleEffect(1.3)

                                var showTrayFull: Bool {
                                    pttManager.state == .idle && newMessages > 0
                                }
                                Image(systemName: "tray.full")
                                    .foregroundStyle(.white)
                                    .opacity(showTrayFull ? 1 : 0)
                                    .scaleEffect(1.3)

                                Image(systemName: "tray.and.arrow.down")
                                    .foregroundStyle(.accent, .white)
                                    .opacity(isPlaying ? 1 : 0)
                                    .scaleEffect(1.3)
                                    .offset(y: -3)
                            }

                            .fontWeight(.bold)
                            .animation(.linear(duration: 0.1), value: pttManager.state)
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 55)
                    .padding(.top, 5)

                    ChannelUsersView()
                        .padding(.horizontal, 15)
                    Spacer(minLength: 0)
                    HStack {
                        ZStack {
                            Image(systemName: iconVolume)
                                .foregroundStyle(.white)
                                .font(.title3)
                                .opacity(!isRecording ? 1 : 0)
                                .offset(x: !isRecording ? 0 : -50)
                                .opacity(self.showVolume ? 0 : 1)
                                .offset(y: self.showVolume ? 20 : 0)
                                .animation(.default, value: showVolume)
                                .opacity(showUserMap ? 0 : 1)
                                .VButton(onRelease: { _ in
                                    self.showVolume.toggle()
                                    return true
                                })
                                .frame(width: 35)

                            VStack(spacing: 5) {
                                Text(verbatim: String(format: "%.1f", pttManager.elapsedTime))
                                    .font(.numberStyle(size: 28))
                                    .fontWeight(.black)
                                    .lineLimit(1)
                                    .opacity(isRecording ? 1 : 0)
                                    .scaleEffect(isRecording ? 1 : 0.1)
                                    .offset(y: isRecording ? 0 : -30)

                                Text(verbatim: "TIME")
                                    .lineLimit(1)
                                    .opacity(isRecording ? 1 : 0)
                                    .scaleEffect(isRecording ? 1 : 0.1)
                                    .offset(y: isRecording ? 0 : 30)
                            }
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .frame(width: 50)
                            .diff { view in
                                Group {
                                    if showUserMap && isRecording {
                                        view
                                            .padding(5)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(5)
                                    } else {
                                        view
                                    }
                                }
                            }
                        }

                        .animation(.default, value: pttManager.state)

                        Spacer()

                        MhzAndKhzView()
                            .opacity(showUserMap ? 0 : 1)

                        Spacer()
                        // TODO: -

                        Image(systemName: "slider.horizontal.3")
                            .font(.title)
                            .foregroundStyle(.white)
                            .VButton { _ in
                                self.showSettings.toggle()
                                return true
                            }
                    }
                    .padding(.horizontal, 10)

                    HStack {
                        ZStack {
                            let show1 = pttManager.state == .idle && pttManager.waitPlayList
                                .count > 0
                            Image(systemName: "livephoto.play")
                                .padding(.horizontal, 10)
                                .opacity(show1 ? 1 : 0)
                                .offset(x: show1 ? 0 : 50)
                                .animation(.linear(duration: 0.2), value: pttManager.state)
                                .VButton { _ in
                                    Task {
                                        await pttManager.playWaitList()
                                    }
                                    return true
                                }

                            Image(systemName: "stop.circle")
                                .padding(.horizontal, 10)
                                .opacity(isPlaying ? 1 : 0)
                                .offset(x: isPlaying ? 0 : 50)
                                .animation(.linear(duration: 0.2), value: pttManager.state)
                                .VButton { _ in
                                    // TODO: - 停止播放
                                    Task {
                                        await self.pttManager.send(.stopPlay)
                                    }

                                    // TODO: - 播放音乐
                                    Task {
                                        await pttManager.playWaitList()
                                    }
                                    return true
                                }
                        }

                        Spacer(minLength: 0)

                        Text(stateTitle)
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .diff { view in
                                Group {
                                    if showUserMap && (isPlaying || isRecording) {
                                        view
                                            .padding(3)
                                            .padding(.horizontal)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(5)
                                    } else {
                                        view
                                    }
                                }
                            }

                        Spacer(minLength: 0)

                        Image(systemName: "forward")
                            .padding(.horizontal, 10)
                            .opacity(isPlaying && pttManager.waitPlayList
                                .count > 0 ? 1 : 0)
                            .VButton { _ in
                                // TODO: - 下一条
                                Task {
                                    await self.pttManager.playWaitList()
                                }
                                return true
                            }

                        Image("music")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(pttMusicPlay ? .black : .white.opacity(0.5))
                            .opacity(isPlaying ? 0 : 1)
                            .offset(x: isPlaying ? -50 : 0)
                            .animation(.linear(duration: 0.2), value: pttManager.state)
                            .padding(.horizontal, 10)
                            .opacity(showUserMap ? 0 : 1)
                            .VButton { _ in
                                self.pttMusicPlay.toggle()

                                return true
                            }

                        Image("vibration")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(pttVibration ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .opacity(showUserMap ? 0 : 1)
                            .VButton { _ in
                                self.pttVibration.toggle()

                                return true
                            }
                    }
                    .frame(height: 35)
                    .font(.title2)
                    .minimumScaleFactor(0.8)

                    HStack(alignment: .bottom) {
                        Image("logo1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(3)
                            .environment(\.colorScheme, pttManager.powerState ? .light : .dark)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard showUserMapTem else { return }
                                        pttManager.animateRegionChange = false

                                        if logoDragStartRegion == nil {
                                            logoDragStartRegion = pttManager.region
                                        }
                                        guard let baseRegion = logoDragStartRegion else { return }

                                        let scale = pow(1.01, value.translation.height)
                                        pttManager.scaleMapAroundCenter(
                                            from: baseRegion,
                                            scale: scale,
                                            animated: false
                                        )
                                    }
                                    .onEnded { value in
                                        defer {
                                            logoDragStartRegion = nil
                                            pttManager.animateRegionChange = true
                                        }
                                        guard showUserMapTem else { return }

                                        let isTap = abs(value.translation.width) < 8 &&
                                            abs(value.translation.height) < 8
                                        if isTap {
                                            pttManager.zoomToFitAllUsers()
                                            Haptic.impact()
                                        }
                                    }
                            )

                        Spacer(minLength: 0)

                        Picker(selection: $pttChannel.server) {
                            var pttServers: [PushServerModel] {
                                var servers = servers.filter { $0.status > 1 }
                                servers.insert(PushServerModel.noServer, at: 0)
                                return servers
                            }
                            ForEach(pttServers, id: \.self) { server in
                                Text(server.name)
                                    .tag(server)
                            }
                        } label: { Text("切换服务器") }
                            .tint(pttChannel.serverOK ? .black : .red)
                            .pickerStyle(MenuPickerStyle())
                            .offset(x: 10)
                            .opacity(showUserMap ? 0 : 1)
                    }
                    Spacer(minLength: 0)

                    HStack {
                        Text(verbatim: String(format: "%.1f", pttManager.currentPlayTime))
                            .font(.numberStyle(size: 16))
                            .fontWeight(.black)
                            .lineLimit(1)
                            .opacity(isPlaying ? 1 : 0.3)

                        if isPlaying {
                            VolumePeakView(
                                progress: currentProgress,
                                activeTint: .primary,
                                inActiveTint: .white.opacity(0.3),
                                anchor: .leading
                            )
                            .transition(.opacity)
                        } else {
                            VolumePeakView(
                                progress: currentProgress,
                                activeTint: .primary,
                                inActiveTint: .white.opacity(0.3),
                                anchor: .trailing
                            )
                            .transition(.opacity)
                        }

                        Text(verbatim: String(format: "%.1f", pttManager.totalPlayTime))
                            .font(.numberStyle(size: 16))
                            .fontWeight(.black)
                            .lineLimit(1)
                            .opacity(isPlaying ? 1 : 0.3)
                    }
                    .frame(height: 12)
                    .padding(.bottom, 5)
                    .animation(.linear(duration: 0.3), value: pttManager.state)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            .frame(height: 380)

            CenterButtonsView()

            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(.gray.opacity(0.3))
                .frame(height: 5)
                .padding(.horizontal, 10)

            BottomBottonViews()
        }
        .background(.background)
        .ignoresSafeArea(.container, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            SetVolumePeakView(show: $showVolume, volume: $pttVoiceVolume, icon: iconVolume)
                .onChange(of: pttVoiceVolume) { value in
                    Task {
                        await pttManager.setDB(Float(value))
                    }
                }
        }
        .overlay(alignment: .bottomLeading) {
            TabBarBackButtonView(size: CGSize(width: 300, height: 0))
                .offset(x: 30)
        }
        .animation(.default, value: showVolume)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showVoiceList) {
            PTTMessageView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showChannelList) {
            HistoryChannelListView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) {
            PTTSettingsView()
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    func GreenbackgroundView() -> some View {
        let topshape = UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 35,
            bottomTrailingRadius: 35,
            topTrailingRadius: 0
        )

        topshape
            .fill(
                LinearGradient(
                    colors: [Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.4, green: 0.8, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.3728182146, green: 0.7853954082, blue: 0, alpha: 1))],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if pttManager.powerState {
                    topshape
                        .stroke(.white, lineWidth: 5)
                        .blur(radius: 10)
                }
            }
            .overlay {
                if !pttManager.powerState {
                    Color.black
                        .opacity(0.1)
                }
            }
            .overlay {
                if showUserMap {
                    ChannelUserMapUIKitView(
                        region: $pttManager.region,
                        animateRegionChanges: pttManager.animateRegionChange,
                        onlineUsers: pttManager.onlineUsers
                    )
                }
            }
    }

    private func scheduleAutoHide() {
        // 取消之前的任务
        hideWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            withAnimation {
                showVolume = false
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    @ViewBuilder
    func ChannelUsersView() -> some View {
        HStack {
            HStack(alignment: .bottom, spacing: 0) {
                Text(verbatim: String(format: "%02d", pttChannel.users.count))
                    .font(.numberStyle(size: 20))
                    .offset(y: 2)
                    .foregroundStyle(pttChannel.users.count > 0 ?
                        Color.white : Color.white.opacity(0.3))
                    .fontWeight(.bold)
                    .tracking(3)
                    .offset(y: pttManager.state == .recording ? 30 : 0)
                    .opacity(pttManager.state == .recording ? 0 : 1)
                    .animation(.default, value: pttManager.state)
                    .animation(.default, value: pttManager.state)

                ForEach(Array(0...2), id: \.self) { item in
                    Image(systemName: "person")
                        .diff { view in
                            Group {
                                if item > pttChannel.users.count - 1 {
                                    view
                                        .foregroundStyle(.white.opacity(0.1))
                                } else {
                                    view
                                        .foregroundStyle(showUserMap ? .green : .black)
                                        .symbolVariant(.fill)
                                }
                            }
                        }
                        .animation(.default, value: pttChannel.users)
                        .VButton{ _ in
                            self.showUserMapTem.toggle()
                            return true
                        }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut) {
                    pttManager.zoomToFitAllUsers()
                }
            }

            Spacer(minLength: 0)

            Text(verbatim: String(format: "%02d", pttManager.waitPlayList.count))
                .font(.numberStyle(size: 20))
                .opacity(pttManager.waitPlayList.count > 0 ? 1 : 0)
        }
    }

    @ViewBuilder
    func powerButton() -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.gray.opacity(dragOffset > 0 ? 0.15 : 0.06))
                .frame(width: maxDragDistance, height: 50)
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.08), lineWidth: 3)
                        .blur(radius: 2)
                        .offset(y: 2)
                        .mask(Capsule())
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .offset(y: -0.5)
                        .mask(Capsule())
                )

                .overlay(
                    ZStack(alignment: .leading) {
                        HStack(spacing: 4) {
                            Text(pttManager.powerState ? "关闭" : "开启")
                            Image(systemName: "chevron.right.2")
                                .offset(x: isAnimatingHint ? 0 : -6)
                        }
                        .font(.footnote)
                        .bold()
                        .foregroundColor(.secondary)
                        .offset(x: dragOffset >= (maxDragDistance - 30) / 2 ? 10 : -10)
                        .opacity(isAnimatingHint ? 0.3 : 0.8)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true))
                            {
                                self.isAnimatingHint = true
                            }
                        }
                    },
                    alignment:  dragOffset >= (maxDragDistance - 30) / 2 ? .leading : .trailing
                )
                .offset(x: 10)

            Image(systemName: "power.circle.fill")
                .foregroundStyle(pttManager.powerState ? Color.red.gradient : Color.green.gradient)
                .font(.system(size: 50))
                .offset(x: buttonType == .call ? dragOffset : 0)
                .gesture(
                    DragGesture(
                        minimumDistance: 0,
                        coordinateSpace: .local
                    )
                    .onChanged { value in
                        let currentWidth = value.translation.width
                        self.dragOffset = max(0, min(currentWidth, maxDragDistance - 30))
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                            self.dragOffset = 0.0
                        }

                        let draggedWidth = value.translation.width

                        if draggedWidth >= maxDragDistance - 50 {
                            if pttManager.powerState {
                                PTTChannelManager.shared.leave()
                                self.showUserMapTem = false
                            } else {
                                pttHisChannel.set(pttChannel, active: true)
                                PTTChannelManager.shared.join()
                            }

                            Haptic.impact()
                        }
                    }
                )
        }
        .opacity(buttonType == .call ? 1 : 0)
        .scaleEffect(buttonType == .call ? 1 : 0.5)
    }

    @ViewBuilder
    func CenterButtonsView() -> some View {
        ZStack {
            HStack {
                Button {
                    withAnimation {
                        self.buttonType = .call
                    }

                    Haptic.impact()
                } label: {
                    Image(systemName: "arrow.backward")
                        .font(.largeTitle)
                        .padding(.leading, 10)
                }
                .transition(.move(edge: .leading))
                .padding(.trailing, 20)
                .offset(x: buttonType == .mhz || buttonType == .khz ? 0 : -100)
                .animation(.easeInOut, value: buttonType)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            .opacity(buttonType == .mhz || buttonType == .khz ? 1 : 0)

            ZStack {
                HStack(spacing: 20) {
                    powerButton()

                    Spacer()
                }
                HStack(spacing: 20) {
                    Spacer()

                    Button {
                        self.showVoiceList.toggle()
                        Haptic.impact()
                    } label: {
                        Image(systemName: "captions.bubble")
                            .foregroundStyle(.white, .accent)
                            .font(.largeTitle)
                    }
                    .offset(x: buttonType == .call ? 0 : -100)
                    .scaleEffect(buttonType == .call ? 1 : 0.5)
                    .offset(x: 30)

                    Spacer(minLength: 0)
                }
                HStack(spacing: 20) {
                    Spacer(minLength: 0)

                    Button {
                        // TODO: - 总设置
                        if pttHisChannel.count > 0 {
                            self.showChannelList.toggle()
                        } else {
                            Toast.info(title: "没有历史频道")
                        }
                        Haptic.impact()

                    } label: {
                        Label {
                            Text("历史频道")
                        } icon: {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundStyle(.white, .accent)
                                .font(.largeTitle)
                        }
                        .labelStyle(.iconOnly)
                    }
                    .offset(x: buttonType == .call ? 0 : 100)
                }
            }

            .padding(.horizontal, 10)
            .opacity(buttonType == .call ? 1 : 0)
            .animation(.easeInOut, value: buttonType)
        }
    }

    @ViewBuilder
    func BottomBottonViews() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minDimension = min(proxy.size.width, proxy.size.height)
            ZStack {
                ZStack {
                    RotateButtonView { changeTalkChannel($0) }
                        .padding(30)
                        .scaleEffect(buttonType == .mhz || buttonType == .khz ? 1 : 0.5)
                        .opacity(buttonType == .mhz || buttonType == .khz ? 1 : 0)

                    ZStack {
                        Circle()
                            .fill(buttonColor.gradient)
                            .frame(width: minDimension / 2, height: minDimension / 2)
                            .blur(radius: 20)

                        Circle()
                            .stroke(buttonColor.gradient, lineWidth: 50)
                            .padding(50)
                            .blur(radius: 10)

                        Image("voice")
                            .resizable()
                            .renderingMode((ispress && !isCancel) ? .template : .original)
                            .foregroundStyle(.black)
                            .frame(width: minDimension, height: minDimension)
                            .scaleEffect(ispress ? 0.95 : 1)

                        Circle()
                            .stroke(buttonColor.gradient, lineWidth: 20)
                            .padding(35)
                            .blur(radius: 10)
                        Circle()
                            .stroke(buttonColor, lineWidth: 15)
                            .padding(30)

                        Text(verbatim: "PTT")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(ispress ? buttonColor : .white)
                            .scaleEffect(ispress ? 1.2 : 1)
                    }

                    .pbutton(
                        $isCancel,
                        $ispress,
                        onBegan: {
                            Task {
                                await startRecording()
                            }
                        },
                        onEnded: {
                            Task {
                                await endRecording()
                            }
                        },
                        onCancelled: {
                            Task {
                                await cancelRecording()
                            }
                        }
                    )
                    .disabled(!pttManager.powerState)
                    .scaleEffect(buttonType == .call ? 1 : 0.5)
                    .opacity(buttonType == .call ? 1 : 0)
                }
                .frame(maxWidth: minDimension, maxHeight: minDimension) // 限制 iPad
                .animation(.easeInOut(duration: 0.1), value: ispress)
            }
            .frame(width: size.width, height: size.height, alignment: .center)
        }
    }

    @ViewBuilder
    func MhzAndKhzView() -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(verbatim: "\(mhzTem == -1 ? pttChannel.mhz : mhzTem)")
                .foregroundStyle(buttonType == .mhz ? .red : .white)
                .contentShape(Rectangle())
                .VButton { _ in
                    guard !pttManager.powerState else {
                        Toast.info(title: "请先关闭监听!")
                        return false
                    }
                    withAnimation {
                        self.buttonType = self.buttonType == .mhz ? .call : .mhz
                    }

                    return true
                }

            Text(verbatim: ".")
                .foregroundStyle(.white)

            Text(
                verbatim: "\(khzTem == -1 ? pttChannel.khz.KHZ() : khzTem.KHZ())"
            )
            .foregroundStyle(buttonType == .khz ? .red : .white)
            .contentShape(Rectangle())
            .VButton { _ in
                guard !pttManager.powerState else {
                    Toast.info(title: "请先关闭监听!")
                    return false
                }
                withAnimation {
                    self.buttonType = self.buttonType == .khz ? .call : .khz
                }
                return true
            }
        }
        .font(.numberStyle(size: 70))
        .fontWeight(.black)
    }

    func startRecording() async {
        if pttMusicPlay {
            pttManager.playTips(.cbegin) {}
        }

        if pttVibration { Haptic.impact(.heavy) }

        guard self.ispress else { return }
        await pttManager.send(.startRecord(true))
    }

    func endRecording() async {
        await pttManager.send(.stopRecord(false))

        if pttVibration {
            Haptic.notify(.success)
        }

        if pttMusicPlay {
            pttManager.playTips(.pttnotifyend)
        }
    }

    func cancelRecording() async {
        await pttManager.send(.stopRecord(true))
        if pttVibration {
            Haptic.notify(.error)
        }
    }

    func changeTalkChannel(_ angle: Int) {
        if angle == 0 {
            switch buttonType {
            case .mhz where mhzTem >= 0:
                pttChannel.mhz = mhzTem
                mhzTem = -1
            case .khz where khzTem >= 0:
                pttChannel.khz = khzTem
                khzTem = -1
            default:
                break
            }
            return
        }

        let value = abs(angle / 360)
        let number: Int = {
            if value == 0 {
                return angle / 10
            } else if angle < 0 {
                return (angle + 360) / 3 - 36
            } else {
                return (angle - 360) / 3 + 36
            }
        }()

        guard number != historyNumber else { return }
        historyNumber = number
        Haptic.selection()

        switch buttonType {
        case .mhz:
            mhzTem = max(1, min(999, number + pttChannel.mhz))
        case .khz:
            khzTem = max(0, min(999, number + pttChannel.khz))
        case .call: break
        }
    }
}

private struct SetVolumePeakView: View {
    @Binding var show: Bool
    @Binding var volume: CGFloat
    var icon: String

    @State private var hideWorkItem: DispatchWorkItem?
    @State private var isPress: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray.opacity(0.0001)
                .VButton(onRelease: { _ in
                    self.show.toggle()
                    return true
                })
            CustomSlider(
                isPress: $isPress,
                sliderProgress: $volume,
                symbol: .init(
                    icon: icon,
                    tint: .white,
                    font: .system(size: 20),
                    padding: 20,
                    display: true,
                    alignment: .bottom
                ),
                axis: .vertical,
                tint: volume > 0.3 ? .green : .orange
            )
            .frame(width: 40, height: 140)
            .offset(x: 20)
        }
        .opacity(show ? 1 : 0)
        .offset(y: show ? 0 : -20)
        .onChange(of: volume) { _ in
            if show && !isPress {
                scheduleAutoHide()
            }
        }
        .onChange(of: show) { value in
            if value {
                scheduleAutoHide()
            }
        }
        .onChange(of: isPress) { newValue in
            if newValue {
                hideWorkItem?.cancel()
            } else {
                scheduleAutoHide()
            }
        }
    }

    private func scheduleAutoHide() {
        // 取消之前的任务
        hideWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            withAnimation {
                show = false
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }
}

struct HourAndMinuteView: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(timeString(from: currentTime))
            .onReceive(timer) { _ in
                currentTime = Date()
            }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 24小时制，如果要12小时制改成 "hh:mm a"
        return formatter.string(from: date)
    }
}

struct ToastPttView: View {
    let message: String
    @Binding var isPresented: Bool
    // 内部记录当前的定时器任务，用于在连续点击时重置时间
    @State private var dismissTask: Task<Void, Never>? = nil

    var body: some View {
        VStack {
            if isPresented {
                Text(message)
                    .transition(.move(edge: .top).combined(with: .opacity)) // 出现和消失时的动画效果
                    .onAppear {
                        startDismissTimer()
                    }
                    .onChange(of: isPresented) { newValue in
                        // 如果外部在显示期间再次激活（例如连续点击），重新触发定时器
                        if newValue {
                            startDismissTimer()
                        }
                    }
            }
        }
        // 使用内置动画，让显示和隐藏更丝滑
        .animation(.snappy, value: isPresented)
    }

    /// 核心逻辑：开启 3 秒倒计时任务
    private func startDismissTimer() {
        // 1. 如果之前已经有一个定时器在跑，先取消它（防止多次点击导致闪烁或提早关闭）
        dismissTask?.cancel()

        // 2. 创建新任务
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000) // 等待 3 秒

            // 3. 检查任务是否被取消了，如果没有，在主线程关闭 View
            if !Task.isCancelled {
                await MainActor.run {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    PTTContentView()
}
