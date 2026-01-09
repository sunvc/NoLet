//
//  ScanView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo 2024/8/10.
//

import AVFoundation
import Defaults
import QRScanner
import SwiftUI
import UIKit

struct ScanView: View {
    @State private var isScanning = true
    @State private var isTorchOn = false
    @State private var shouldRescan = false

    @State private var code: String? = nil
    @EnvironmentObject private var manager: AppManager
    @Default(.limitScanningArea) var limitScanningArea
    var response: (String) async -> Void
    var close: (() -> Void)? = nil
    var config: QRScannerSwiftUIView.Configuration {
        .init(
            focusImage: nil,
            focusImagePadding: nil,
            animationDuration: nil,
            scanningAreaLimit: limitScanningArea,
            metadataObjectTypes: [.qr, .aztec, .microQR, .dataMatrix]
        )
    }

    var body: some View {
        ZStack {
            QRScannerSwiftUIView(
                configuration: config,
                isScanning: $isScanning,
                torchActive: $isTorchOn,
                shouldRescan: $shouldRescan,
                onSuccess: { code in
                    Task.detached {
                        await Tone.play(.qrcode)
                    }

                    Task { @MainActor in
                        try await Task.sleep(for: .seconds(0.5))
                        self.code = code
                        await response(code)
                    }
                },
                onFailure: { error in
                    switch error {
                    case .unauthorized(let status):
                        if status != .authorized {
                            Toast.info(title: "没有相机权限")
                        }
                    default:
                        Toast.error(title: "扫码失败")
                        Task.detached {
                            await Tone.play("1053")
                        }
                    }
                    Task { @MainActor in
                        self.code = nil
                    }
                },
                onTorchActiveChange: { isOn in
                    isTorchOn = isOn
                }
            )

            VStack {
                HStack {
                    Spacer()
                    Button {
                        if let close = close {
                            close()
                        } else {
                            AppManager.shared.open(full: nil)
                        }
                        Haptic.impact()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                            .padding()
                            .background26(.ultraThinMaterial, radius: 10)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .padding(.top, close == nil ? 50 : 0)
                Spacer()

                Group {
                    if let code = code {
                        VStack {
                            Menu {
                                Section {
                                    Button(role: .destructive) {
                                        self.shouldRescan.toggle()
                                        self.code = nil
                                    } label: {
                                        Label("重新扫码", systemImage: "qrcode.viewfinder")
                                    }
                                }

                                if let url = URL(string: code), code.contains("://") {
                                    Section {
                                        Button {
                                            AppManager.shared.open(full: nil)
                                            AppManager.openURL(url: url, .safari)
                                        } label: {
                                            Label("打开地址", systemImage: "link.circle")
                                        }
                                    }
                                }

                                Section {
                                    Button {
                                        AppManager.shared.open(full: nil)
                                        AppManager.shared.open(sheet: .quickResponseCode(
                                            text: code,
                                            title: String("二维码"),
                                            preview: String("二维码")
                                        ))
                                    } label: {
                                        Label("生成二维码", systemImage: "qrcode")
                                    }
                                }

                            } label: {
                                Text(verbatim: code)
                                    .tint(.accent)
                                    .lineLimit(1)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                                    .padding()
                                    .background26(.ultraThinMaterial, radius: 10)
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" :
                                "flashlight.off.fill")
                                .font(.system(size: 35))
                                .symbolRenderingMode(.palette)
                                .animation(.default, value: isTorchOn )
                                .padding()
                                .contentShape(Rectangle())
                                .if(true) { view in
                                    Group {
                                        if isTorchOn {
                                            view
                                                .foregroundStyle(Color.black)
                                                .background(Circle().fill(.white))
                                        } else {
                                            view
                                                .foregroundStyle(Color.white)
                                                .background26(.ultraThickMaterial, radius: 0)
                                        }
                                    }
                                }
                                .clipShape(Circle())
                                .VButton(onRelease: { _ in
                                    self.isTorchOn.toggle()
                                    return true
                                })
                        }
                    }
                }.padding(.bottom, close == nil ? 80 : 10)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .if(close == nil) { view in
            view
                .gesture(
                    DragGesture(minimumDistance: 30, coordinateSpace: .global)
                        .onChanged { _ in
                            Haptic.selection()
                        }
                        .onEnded { action in
                            if action.translation.height > 100 {
                                AppManager.shared.open(full: nil)
                                Haptic.impact()
                            }
                        }
                )
        }
    }
}

#Preview {
    ScanView { _ in }
}
