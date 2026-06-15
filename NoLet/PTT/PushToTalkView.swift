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

struct PushToTalkView: View {
    @Environment(\.dismiss) var dismiss
    @State private var ispress: Bool = false

    @StateObject private var pttManager = PushTalkManager.shared

    @State private var buttonType: TalkButtonType = .call

    @State private var historyNumber: Int = 0

    @State private var prefixTem: Int = 0
    @State private var suffixTem: Int = 0
    @State private var showSettings: Bool = false

    @Default(.pttChannel) var pttChannel
    @Default(.pttVibration) var pttVibration
    @Default(.pttMusicPlay) var pttMusicPlay
    @Default(.servers) var servers
    @Default(.pttHisChannel) var pttHisChannel
    @Default(.pttVoiceVolume) var pttVoiceVolume
    @Default(.pttSignature) var pttSignature

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

    @State private var isCancel: Bool = false

    @State private var showChannelList: Bool = false
    @State private var showVoiceList: Bool = false

    @State private var offset: CGFloat = 0

    private let throttler5 = Throttler(delay: 0.5)

    private var topshape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 35,
            bottomTrailingRadius: 35,
            topTrailingRadius: 0
        )
    }

    @State private var isEncryption: Bool = true

    @State private var newMessages: Int = 0

    @State private var showVolume: Bool = false
    @State private var hideWorkItem: DispatchWorkItem?

    var currentProgress: Double {
        switch pttManager.state {
        case .idle:
            return 0
        case .preparingPlay:
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

    var isPlaying: Bool { pttManager.state.isPlaying }
    var isRecording: Bool { pttManager.state.isRecording }

    var networkIcon: (String, Color, Color) {
        switch pttManager.serverStatus {
        case .offline:
            return ("network.slash", .red, .primary)
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
        if !pttManager.powerState && !isPlaying {
            return String(localized: "未启动监听")
        } else {
            return pttManager.serverStatus == .failed ?
                String(localized: "服务器未连接") :
                pttManager.state.title
        }
    }

    var body: some View {
        VStack {
            ZStack {
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

                VStack {
                    HStack {
                        HourAndMinuteView()
                            .font(.numberStyle(size: 27))

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
                    HStack {
                        ChannelUsersView()

                        Spacer(minLength: 0)

                        Text(verbatim: String(format: "%02d", pttManager.waitPlayList.count))
                            .font(.numberStyle(size: 20))
                            .opacity(pttManager.waitPlayList.count > 0 ? 1 : 0)
                    }
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
                                .VButton(onRelease: { _ in
                                    self.showVolume.toggle()
                                    return true
                                })
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

                            }.foregroundStyle(.white)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 35)
                        .animation(.default, value: pttManager.state)

                        Spacer()

                        showPrefixAndSuffix()

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
                        Image(systemName: "stop.circle")
                            .padding(.horizontal, 10)
                            .opacity(isPlaying ? 1 : 0)
                            .offset(x: isPlaying ? 0 : 50)
                            .animation(.linear(duration: 0.2), value: pttManager.state)
                            .VButton { _ in
                                // TODO: - 停止播放
                                self.pttManager.send(.stopPlay)
                                return true
                            }
                        Spacer(minLength: 0)

                        Text(stateTitle)
                            .foregroundStyle(.white)

                        Spacer(minLength: 0)

                        Image(systemName: "forward")
                            .padding(.horizontal, 10)
                            .opacity(isPlaying && pttManager.waitPlayList
                                .count > 0 ? 1 : 0)
                            .VButton { _ in
                                // TODO: - 下一条
                                true
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
                            .VButton { _ in
                                // TODO: - 播放音乐
                                pttManager.playWaitList()
                                return true
                            }

                        Spacer(minLength: 0)

                        Picker(selection: $pttChannel.server) {
                            ForEach(servers, id: \.self) { server in
                                Text(server.name)
                                    .tag(server)
                            }
                        } label: { Text("切换服务器") }
                            .tint(.black)
                            .pickerStyle(MenuPickerStyle())
                            .onAppear {
                                if pttChannel.server == nil {
                                    pttChannel.server = servers.first
                                }
                            }
                            .offset(x: 10)
                    }
                    Spacer(minLength: 0)
                    HStack {
                        if isPlaying {
                            Text(verbatim: String(format: "%.1f", pttManager.currentPlayTime))
                                .font(.numberStyle(size: 16))
                                .fontWeight(.black)
                                .lineLimit(1)
                                .offset(x: isPlaying ? 0 : -100)
                        }
                        VolumePeakView(
                            progress: currentProgress,
                            activeTint: .primary,
                            inActiveTint: .white.opacity(0.3),
                            anchor: isPlaying ? .leading : .trailing
                        )
                        if isPlaying {
                            Text(verbatim: String(format: "%.1f", pttManager.totalPlayTime))
                                .font(.numberStyle(size: 16))
                                .fontWeight(.black)
                                .lineLimit(1)
                                .opacity(isPlaying ? 1 : 0)
                                .offset(x: isPlaying ? 0 : 100)
                        }
                    }
                    .frame(height: 12)
                    .padding(.bottom, 5)
                    .animation(.linear(duration: 0.3), value: pttManager.state)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
            .frame(height: 320)
            CenterButtonsView()

            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(.gray.opacity(0.3))
                .frame(height: 5)
                .padding(.horizontal, 10)

            bottonViews()
        }
        .background(.background)
        .ignoresSafeArea(.container, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            SetVolumePeakView(show: $showVolume, volume: $pttVoiceVolume, icon: iconVolume)
                .onChange(of: pttVoiceVolume) { value in
                    pttManager.setDB(Float(value))
                }
        }
        .animation(.default, value: showVolume)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showVoiceList) {
            PTTVoiceListView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showChannelList) {
            PTTChannelListView { item in
                if !pttManager.powerState {
                    var item = item
                    item.timestamp = .now
                    Defaults[.pttChannel] = item
                    self.showChannelList = false
                    return true
                }
                self.showChannelList = false
                return false
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) {
            PTTSettingsView()
                .presentationDetents([.medium, .large])
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
        HStack(alignment: .bottom, spacing: 0) {
            Text(verbatim: String(format: "%02d", pttManager.channelUsers))
                .font(.numberStyle(size: 20))
                .offset(y: 2)
                .foregroundStyle(pttManager.channelUsers > 0 ?
                    Color.white : Color.white.opacity(0.3))
                .fontWeight(.bold)
                .tracking(3)
                .offset(y: pttManager.state == .recording ? 30 : 0)
                .opacity(pttManager.state == .recording ? 0 : 1)
                .animation(.default, value: pttManager.state)
                .animation(.default, value: pttManager.state)

            ForEach(Array(0...2), id: \.self) { item in
                Image(systemName: "person")
                    .if(true) { view in
                        Group {
                            if item > pttManager.channelUsers - 1 {
                                view
                                    .foregroundStyle(.white.opacity(0.1))
                            } else {
                                view
                                    .foregroundStyle(.black)
                                    .symbolVariant(.fill)
                            }
                        }
                    }
                    .animation(.default, value: pttManager.channelUsers)
            }
        }
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
                .offset(x: buttonType == .prefix || buttonType == .suffix ? 0 : -100)
                .animation(.easeInOut, value: buttonType)
                Spacer()

                Button {
                    // TODO: - 总设置
                    if pttHisChannel.count > 0 {
                        self.showChannelList.toggle()
                    } else {
                        Toast.info(title: "没有历史频道")
                    }

                } label: {
                    Label {
                        Text("历史频道")
                    } icon: {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundStyle(.orange, .primary)
                            .font(.title)
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .opacity(buttonType == .prefix || buttonType == .suffix ? 1 : 0)
            HStack(spacing: 20) {
                Button {
                    if pttManager.powerState {
                        pttManager.channelManager?.leaveChannel(channelUUID: pttChannel.channelID)
                    } else {
                        pttManager.channelManager?.requestJoinChannel(
                            channelUUID: pttChannel.channelID,
                            descriptor: .init(name: NCONFIG.AppName, image: "書".avatarImage())
                        )

                        Defaults[.pttHisChannel].set(pttChannel)
                    }

                    Haptic.impact()
                } label: {
                    Image(systemName: "power.circle.fill")
                        .foregroundStyle(pttManager.powerState ? Color.red.gradient : Color.green
                            .gradient)
                        .font(.system(size: 50))
                        .opacity(buttonType == .call ? 1 : 0)
                        .scaleEffect(buttonType == .call ? 1 : 0.5)
                        .offset(x: buttonType == .call ? 0 : 100)
                }

                Spacer()

                Button {
                    self.showVoiceList.toggle()
                    Haptic.impact()
                } label: {
                    Image(systemName: "message.and.waveform")
                        .foregroundStyle(.white, .accent)
                        .font(.largeTitle)
                }
                .offset(x: buttonType == .call ? 0 : -100)
                .scaleEffect(buttonType == .call ? 1 : 0.5)

                Spacer(minLength: 0)
                Button {
                    AppManager.shared.open(full: .none)
                    Haptic.impact()
                } label: {
                    Image(systemName: "house.circle")
                        .font(.largeTitle)
                        .padding(.trailing, 10)

                }.offset(x: buttonType == .call ? 0 : 100)
            }
            .padding(.horizontal, 30)
            .opacity(buttonType == .call ? 1 : 0)
            .animation(.easeInOut, value: buttonType)
        }
    }

    @ViewBuilder
    func bottonViews() -> some View {
        VStack {
            Spacer(minLength: 0)
            ZStack {
                RotateButtonView {
                    dotColor($0, $1)
                } rotate: { changeTalkChannel($0) }
                    .padding(50)
                    .frame(
                        maxWidth: .ISPAD ? minSize / 2 : windowWidth,
                        maxHeight: .ISPAD ? minSize / 2 : windowWidth
                    )
                    .scaleEffect(buttonType == .prefix || buttonType == .suffix ? 1 : 0.5)
                    .opacity(buttonType == .prefix || buttonType == .suffix ? 1 : 0)

                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack {
                        Circle()
                            .fill(buttonColor.gradient)
                            .frame(width: size.width / 2, height: size.width / 2)
                            .blur(radius: 20)

                        Circle()
                            .stroke(buttonColor.gradient, lineWidth: 50)
                            .padding(50)
                            .blur(radius: 10)

                        Image("voice")
                            .resizable()
                            .renderingMode((ispress && !isCancel) ? .template : .original)
                            .frame(width: size.width, height: size.width)
                            .foregroundStyle(.black)
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
                        onBegan: startRecording,
                        onEnded: endRecording,
                        onCancelled: cancelRecording
                    )
                    .disabled(!pttManager.powerState)
                }
                .frame(
                    maxWidth: .ISPAD ? minSize / 2 : windowWidth,
                    maxHeight: .ISPAD ? minSize / 2 : windowWidth
                )
                .animation(Animation.easeInOut(duration: 0.1), value: ispress)
                .scaleEffect(buttonType == .call ? 1 : 0.5)
                .opacity(buttonType == .call ? 1 : 0)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    func showPrefixAndSuffix() -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(verbatim: "\(prefixTem == 0 ? pttChannel.prefix : prefixTem)")
                .foregroundStyle(buttonType == .prefix ? .red : .white)
                .contentShape(Rectangle())
                .VButton { _ in
                    guard !pttManager.powerState else {
                        Toast.info(title: "请先关闭监听!")
                        return false
                    }
                    withAnimation {
                        self.buttonType = self.buttonType == .prefix ? .call : .prefix
                    }

                    return true
                }

            Text(verbatim: ".")
                .foregroundStyle(.white)

            Text(verbatim: "\(suffixTem == 0 ? pttChannel.suffix : suffixTem)")
                .foregroundStyle(buttonType == .suffix ? .red : .white)
                .contentShape(Rectangle())
                .VButton { _ in
                    guard !pttManager.powerState else {
                        Toast.info(title: "请先关闭监听!")
                        return false
                    }
                    withAnimation {
                        self.buttonType = self.buttonType == .suffix ? .call : .suffix
                    }
                    return true
                }
        }
        .font(.numberStyle(size: 70))
        .fontWeight(.black)
    }

    func startRecording() {
        if pttVibration { Haptic.impact(.heavy) }

        if pttMusicPlay {
            pttManager.playTips(.cbegin) {}
        }

        guard self.ispress else { return }
        pttManager.send(.startRecord(true))
    }

    func endRecording() {
        pttManager.send(.stopRecord(false))

        if pttVibration {
            Haptic.notify(.success)
        }

        if pttMusicPlay {
            pttManager.playTips(.pttnotifyend)
        }
    }

    func cancelRecording() {
        pttManager.send(.stopRecord(true))
        if pttVibration {
            Haptic.notify(.error)
        }
    }

    func changeTalkChannel(_ angle: Int) {
        if angle == 0 {
            switch buttonType {
            case .prefix where prefixTem != 0:
                pttChannel.prefix = prefixTem
                prefixTem = 0
            case .suffix where suffixTem != 0:
                pttChannel.suffix = suffixTem
                suffixTem = 0
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
        case .prefix:
            prefixTem = max(10, min(999, number + pttChannel.prefix))
        case .suffix:
            suffixTem = max(1, min(999, number + pttChannel.suffix))
        case .call: break
        }
    }

    func btnStatus(_ isUP: Bool = true) -> Bool {
        if prefixTem == 0 && suffixTem == 0 {
            return false
        }
        switch buttonType {
        case .prefix:
            let status = prefixTem > pttChannel.prefix
            return isUP ? status : !status
        case .suffix:
            let status = suffixTem > pttChannel.suffix
            return isUP ? status : !status
        case .call:
            return false
        }
    }

    func dotColor(_ upNumber: Int = 0, _ angle: Int) -> Color {
        if buttonType == .suffix && (suffixTem >= 999 || suffixTem <= 1) && suffixTem > 0 {
            return upNumber == 0 ? .gray : .red
        } else if buttonType == .prefix && (prefixTem >= 999 || prefixTem <= 10) && prefixTem > 0 {
            return upNumber == 0 ? .gray : .red
        }

        let colors: [Color] = [.gray, .green, .cyan, .blue, .yellow, .orange, .red]
        let number = abs(Int(angle / 360)) + upNumber
        let index = number % colors.count
        return colors[index]
    }

    func selectServerHandler() {
        guard let current = servers.filter({ $0.status }).first else {
            AppManager.shared.router = []
            return
        }

        if let server = pttChannel.server, !servers.contains(server) || pttChannel.server == nil {
            pttChannel.server = current
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

#Preview {
    PushToTalkView()
}
