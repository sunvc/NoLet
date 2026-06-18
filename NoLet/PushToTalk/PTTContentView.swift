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

struct PTTContentView: View {
   
    @State private var ispress: Bool = false

    @ObservedObject private var pttManager = PushTalkManager.shared

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
        if !pttManager.powerState {
            return ("network.slash", .red, .primary)
        }
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

                        MhzAndKhzView()

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
                            .tint(.black)
                            .pickerStyle(MenuPickerStyle())
                            .offset(x: 10)
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
            .frame(height: 320)

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
                    pttManager.setDB(Float(value))
                }
        }
        .animation(.default, value: showVolume)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showVoiceList) {
            AudioMessageListView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showChannelList) {
            PTTChannelHistoryListView()
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
                Text(verbatim: String(format: "%02d", pttChannel.users))
                    .font(.numberStyle(size: 20))
                    .offset(y: 2)
                    .foregroundStyle(pttChannel.users > 0 ?
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
                                if item > pttChannel.users - 1 {
                                    view
                                        .foregroundStyle(.white.opacity(0.1))
                                } else {
                                    view
                                        .foregroundStyle(.black)
                                        .symbolVariant(.fill)
                                }
                            }
                        }
                        .animation(.default, value: pttChannel.users)
                }
            }

            Spacer(minLength: 0)

            Text(verbatim: String(format: "%02d", pttManager.waitPlayList.count))
                .font(.numberStyle(size: 20))
                .opacity(pttManager.waitPlayList.count > 0 ? 1 : 0)
        }
    }
    
    @ViewBuilder
    func powerButton() -> some View{
        Button {
            let channelID = pttManager.kGlobalPTTChannelUUID
            
            if pttManager.powerState {
                pttManager.channelManager?.leaveChannel(channelUUID: channelID)
            }else{
                pttHisChannel.set(pttChannel, active: true)
                pttManager.channelManager?.requestJoinChannel(
                    channelUUID: channelID,
                    descriptor: .init(name: NCONFIG.AppName, image: "書".avatarImage())
                )
            }
            
            withAnimation {
                self.buttonType = .call
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

                powerButton()
            }
            .padding(.horizontal)
            .padding(.top)
            .opacity(buttonType == .mhz || buttonType == .khz ? 1 : 0)
            HStack(spacing: 20) {
                powerButton()

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

                Spacer(minLength: 0)
                
                
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
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.white, .accent)
                            .font(.largeTitle)
                    }
                    .labelStyle(.iconOnly)
                }
                .offset(x: buttonType == .call ? 0 : 100)
            }
            .padding(.horizontal, 30)
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
                        onBegan: startRecording,
                        onEnded: endRecording,
                        onCancelled: cancelRecording
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

    func startRecording() {
        if pttMusicPlay {
            pttManager.playTips(.cbegin) {}
        }

        if pttVibration { Haptic.impact(.heavy) }

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

#Preview {
    PTTContentView()
}
