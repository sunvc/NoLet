//
//  PTTSessingsView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import Defaults
import PhotosUI
import SwiftUI


struct PTTSettingsView: View {
    @ObservedObject private var manager = PTTManager.shared
    @ObservedObject private var locManager = LocManager.shared
    @Environment(\.dismiss) private var dismiss
    @Default(.eqBands) private var eqBands
    @Default(.pttVibration) private var pttVibration
    @Default(.pttMusicPlay) private var pttMusicPlay
    @Default(.pttVoiceVolume) private var pttVoiceVolume
    @Default(.pttSignature) private var pttSignature
    @Default(.pttBitrate) private var pttBitrate
    @Default(.eqPreset) private var eqPreset
    @Default(.member) private var member
    @State private var refreshId = UUID()
    @State private var showSelectImage: Bool = false
    @State private var isEditing: Bool = false
    @State private var nikeName: String = ""
    @State private var pendingAvatarImage: UIImage? = nil
    @State private var showLoading: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            if let pendingAvatarImage {
                                Image(uiImage: pendingAvatarImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                AvatarView(
                                    icon: Defaults[.member].id,
                                    defaultAvatar: "person.crop.circle.fill",
                                    refreshId: refreshId,
                                    textImage: false
                                )
                            }

                            if isEditing {
                                Circle()
                                    .fill(Color.black.opacity(0.35))
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                            }
                        }
                        .glassCard(100)
                        .foregroundStyle(.secondary)
                        .background(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .onTapGesture {
                            guard isEditing else { return }
                            self.showSelectImage.toggle()
                        }

                        HStack {
                            if isEditing {
                                TextField("请输入昵称", text: $nikeName)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 160)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(member.name.isEmpty ? "未设置昵称" : member.name)
                                    .font(.title3.bold())
                                    .foregroundStyle(member.name.isEmpty ? .secondary : .primary)
                            }
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .imageImporter(isPresented: $showSelectImage) { result in
                        switch result {
                        case .success(let image):
                            self.pendingAvatarImage = image
                        case .failure(let failure):
                            logger.error("\(failure.localizedDescription)")
                            Toast.error(title: "添加失败")
                        }
                    }
                }
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                LocationStatusView()

                Section {
                    Toggle(isOn: $pttSignature) {
                        Label {
                            Text("加密")
                        } icon: {
                            Image(systemName: "key.icloud")
                                .foregroundStyle(.green, .primary)
                        }
                    }
                }
                Section {
                    Toggle(isOn: $pttVibration) {
                        Label {
                            Text("震动")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundStyle(.primary, .green)
                        }
                    }

                    Toggle(isOn: $pttMusicPlay) {
                        Label {
                            Text("提示音")
                        } icon: {
                            Image(systemName: "speaker.zzz")
                                .foregroundStyle(.primary, .green)
                        }
                    }
                }

                Section {
                    Slider(value: $pttVoiceVolume, in: 0...1) {
                        Label {
                            Text("音量")
                        } icon: {
                            Image(systemName: "speaker.wave.2.circle")
                        }
                    }

                } header: {
                    Text("播放音量")
                }

                bitrateSection

                equalizerView
            }
            .navigationTitle("PTT设置")
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        HStack(spacing: 12) {
                            Button {
                                cancelEditing()
                            } label: {
                                Text("取消")
                            }

                            Button {
                                Task { await saveProfile() }
                            } label: {
                                if showLoading {
                                    ProgressView()
                                } else {
                                    Text("保存").bold()
                                }
                            }
                            .disabled(showLoading)
                        }
                    } else {
                        Button {
                            startEditing()
                        } label: {
                            Text("编辑")
                        }
                    }
                }
            }
        }
    }

    private func startEditing() {
        self.nikeName = member.name
        self.pendingAvatarImage = nil
        self.isEditing = true
    }

    private func cancelEditing() {
        self.nikeName = member.name
        self.pendingAvatarImage = nil
        self.isEditing = false
    }

    private func saveProfile() async {
        self.showLoading = true
        defer { self.showLoading = false }
        
        do{
            var member = self.member
        
            let trimmed = nikeName.trimmingCharacters(in: .whitespacesAndNewlines)

            let name = String(trimmed.prefix(5))

            if name.count > 0 {
                member.name = name
            }

            if let image = imageHandler(image: self.pendingAvatarImage) {
                member.newAvatar = image
            }
            let response = try await member.save(to: NCONFIG.publicCloudDatabase)
            
            if let data = response{
                self.member = data
                self.pendingAvatarImage = nil
                self.isEditing = false
            }else{
                Toast.info(title: "保存失败")
            }
        }catch{
            logger.error("\(error.localizedDescription)")
            Toast.error(title: "发生错误")
        }
    
        
    }

    private var bitrateSection: some View {
        Section {
            Picker(selection: bitrateBinding) {
                ForEach(PTTBitrate.allCases) { item in
                    Text(item.displayName).tag(item)
                }
            } label: {
                Label {
                    Text("录音码率")
                } icon: {
                    Image(systemName: "waveform.badge.mic")
                        .foregroundStyle(.green, .primary)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("录音质量")
        } footer: {
            Text(currentBitrate.subtitle)
        }
    }

    private var currentBitrate: PTTBitrate {
        if let hit = PTTBitrate(rawValue: pttBitrate) { return hit }
        return PTTBitrate.allCases.min(by: {
            abs($0.rawValue - pttBitrate) < abs($1.rawValue - pttBitrate)
        }) ?? .normal
    }

    private var bitrateBinding: Binding<PTTBitrate> {
        Binding(
            get: { currentBitrate },
            set: { pttBitrate = $0.rawValue }
        )
    }

    private var equalizerView: some View {
        Section {
            EQSliderView()
                .frame(height: 180)
                .padding(.vertical, 10)

            EQGlobalGainSlider()

        } header: {
            HStack {
                Text("音效调整器")
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Picker(selection: $eqPreset) {
                    ForEach(EqualizerPreset.allCases, id: \.self) { item in
                        Section {
                            Label {
                                Text(item.displayName)
                                    .tag(item)
                            } icon: {
                                Image(systemName: item.iconName)
                            }
                        }
                    }
                } label: { Text("切换服务器") }
                    .pickerStyle(MenuPickerStyle())
                    .offset(x: 10)
                    .onChange(of: eqBands) { _ in
                        Task {
                            await manager.changeEQ()
                        }
                    }
            }
        }
        .listSectionSeparator(.hidden)
    }

    private func imageHandler(image: UIImage?) -> URL? {
        if let data = image?.pngData(),
           let image = data.toThumbnail(),
           let data = image.pngData()
        {
            do {
                let temPng = FileManager.default.temporaryDirectory
                    .appendingPathComponent(
                        "avatar.png",
                        conformingTo: .image
                    )

                try data.write(to: temPng)

                return temPng
            } catch {
                Toast.error(title: "保存失败")
            }
            
        }
        return nil
    }
}

struct LocationStatusView: View {
    @ObservedObject private var locManager = LocManager.shared
    var body: some View {
        Section {
            switch locManager.authorizationStatus {
            case .notDetermined:
                Button("授权使用位置") {
                    locManager.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)

            case .authorizedWhenInUse, .authorizedAlways:
                Toggle(isOn: .constant(true)) {
                    Label {
                        Text("已获得定位权限")
                    } icon: {
                        Image(systemName: "location.circle")
                            .foregroundStyle(.green, .primary)
                    }
                }

            default:
                ListButton {
                    Label {
                        Text("系统设置")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "gear.circle")

                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task { @MainActor in
                        AppManager.openSetting()
                    }
                    return true
                }
            }
        } header: {
            Group {
                switch locManager.authorizationStatus {
                case .notDetermined:
                    Text("需要您的位置信息")

                case .restricted, .denied:
                    Text("未获得定位权限")
                        .foregroundColor(.red)

                case .authorizedWhenInUse:
                    Text("App使用期间")
                        .foregroundColor(.green)

                case .authorizedAlways:
                    Text("始终")
                        .foregroundColor(.green)

                @unknown default:
                    Text("未知状态")
                        .foregroundColor(.orange)
                }
            }
            .font(.footnote)
        }
    }
}
