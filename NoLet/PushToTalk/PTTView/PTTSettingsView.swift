//
//  PTTSessingsView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import Defaults
import PhotosUI
import SwiftUI

/// PTTSettingsView
///
///

struct PTTSettingsView: View {
    @ObservedObject private var manager = PTTManager.shared
    @ObservedObject private var locManager = LocManager.shared
    @Environment(\.dismiss) private var dismiss
    @Default(.eqBands) private var eqBands
    @Default(.pttVibration) private var pttVibration
    @Default(.pttMusicPlay) private var pttMusicPlay
    @Default(.pttVoiceVolume) private var pttVoiceVolume
    @Default(.pttSignature) private var pttSignature
    @Default(.pttNickname) private var pttNickname
    @Default(.eqPreset) private var eqPreset
    @State private var refreshId = UUID()
    @State private var showSelectImage: Bool = false
    @State private var showEdit: Bool = false
    @State private var nikeName: String = ""
    @State private var showLoading: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            AvatarView(
                                icon: Defaults[.id],
                                defaultAvatar: "person.crop.circle.fill",
                                refreshId: refreshId,
                                textImage: false
                            )
                            .onTapGesture {
                                self.showSelectImage.toggle()
                            }
                        }
                        .glassCard(100)
                        .foregroundStyle(.secondary)
                        .background(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())

                        HStack {
                            if showEdit {
                                TextField("请输入昵称", text: $nikeName)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 100)
                                    .customField(icon: "checkmark.seal") {
                                        if !nikeName.isEmpty {
                                            self.showEdit = false
                                            self.pttNickname = String(nikeName.prefix(5))
                                        }
                                    }
                                    .onAppear {
                                        self.nikeName = pttNickname
                                    }
                            } else {
                                Text(pttNickname)
                                    .font(.title3.bold())
                                    .onTapGesture {
                                        self.showEdit = true
                                    }
                            }
                        }
                        .padding(.top)
                        .onAppear {
                            if self.pttNickname.isEmpty {
                                self.showEdit = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .imageImporter(isPresented: $showSelectImage) { result in
                        switch result {
                        case .success(let image):
                            Task {
                                await imageHandler(image: image)
                            }
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

                equalizerView
            }
            .navigationTitle("PTT设置")
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
        }
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
                        Section{
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

    private func toPushIcon(_ data: Data, name: String = "") -> PushIcon? {
        if let image = data.toThumbnail(max: 300) {
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("cloudIcon.png")

            guard let pngData = image.pngData() else { return nil }

            do {
                try pngData.write(to: tempURL)
                return PushIcon(
                    id: UUID().uuidString,
                    name: name,
                    description: [],
                    size: pngData.count,
                    sha256: pngData.sha256(),
                    file: tempURL,
                    previewImage: image
                )
            } catch {
                logger.error("\(error)")
            }
        }
        return nil
    }

    private func imageHandler(image: UIImage) async {
        if let data = image.pngData(), var pushIcon = toPushIcon(data) {
            do {
                let temPng = FileManager.default.temporaryDirectory
                    .appendingPathComponent(
                        "avatar.png",
                        conformingTo: .image
                    )

                try data.write(to: temPng)

                pushIcon.name = Defaults[.id]
                let record = pushIcon.toRecord(recordType: CloudManager.pushIconName)

                let (success, _) = await CloudManager.shared
                    .savePushIconModel(record, file: temPng)
                if success {
                    try? await ImageManager.customCache
                        .removeImage(forKey: Defaults[.id])

                    await ImageManager.storeImage(
                        data: data,
                        key: Defaults[.id],
                        expiration: .days(99999)
                    )
                    await MainActor.run {
                        self.refreshId = UUID()
                    }
                } else {
                    Toast.error(title: "保存失败")
                }
            } catch {
                Toast.error(title: "保存失败")
            }
        }
    }
}

struct LocationStatusView: View {
    @ObservedObject private var locManager = LocManager.shared
    var body: some View {
        Section {
            // 1. 根据不同的权限状态显示不同的 UI
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
            // 1. 根据不同的权限状态显示不同的 UI
            Group{
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
