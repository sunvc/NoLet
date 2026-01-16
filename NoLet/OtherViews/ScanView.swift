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

    @State private var code: String? = nil
    @EnvironmentObject private var manager: AppManager
    @State private var scale: Double = 1
    @GestureState private var gestureScale: CGFloat = 1.0

    var response: (String) async -> Void
    var close: (() -> Void)? = nil
    var config: QRScannerSwiftUIView.Configuration {
        .init(
            focusImage: nil,
            focusImagePadding: nil,
            metadataObjectTypes: [.qr, .aztec, .microQR, .dataMatrix]
        )
    }

    var body: some View {
        ZStack {
            QRScannerSwiftUIView(
                configuration: config,
                isScanning: $isScanning,
                torchActive: $isTorchOn,
                videoZoomFactor: scale * gestureScale,
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

                HStack(spacing: 20) {
                    Spacer()
                    if let code = code, let url = URL(string: code), code.contains("://") {
                        Section {
                            Button {
                                AppManager.shared.open(full: nil)
                                AppManager.openURL(url: url, .safari)
                            } label: {
                                Image(systemName: "link.circle")
                                    .font(.system(size: 35))
                            }
                        }
                        Spacer()
                    }

                    Image(systemName: isTorchOn ? "flashlight.on.fill" :
                        "flashlight.off.fill")
                        .font(.system(size: 35))
                        .symbolRenderingMode(.palette)
                        .animation(.default, value: isTorchOn)
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

                    if let code = code {
                        Spacer()
                        Button {
                            AppManager.shared.open(full: nil)
                            AppManager.shared.open(sheet: .quickResponseCode(
                                text: code,
                                title: String("二维码"),
                                preview: String("二维码")
                            ))
                        } label: {
                            Image(systemName: "qrcode")
                                .font(.system(size: 35))
                        }
                    }
                    
                    Spacer()
                }
            }.padding(.bottom, close == nil ? 80 : 10)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .simultaneousGesture(
            MagnificationGesture()
                .updating($gestureScale) { value, state, _ in
                    state = value
                }
                .onEnded { value in
                    let newScale = scale * value
                    withAnimation {
                        scale = min(max(newScale, 1.0), 10.0)
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    withAnimation {
                        if scale >= 1.0, scale < 2.0 {
                            self.scale = 2.0
                        } else if scale >= 2.0, scale < 6.0 {
                            self.scale = 6.0
                        } else {
                            scale = 1.0
                        }
                    }
                }
        )
        .if(close == nil) { view in
            view
                .simultaneousGesture(
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
