//
//  ScanView.swift
//  Meow
//
//  Created by uuneo 2024/8/10.
//


import SwiftUI
import AVFoundation
import QRScanner
import UIKit
import Defaults



struct ScanView: View {
	@Environment(\.dismiss) var dismiss
    @State private var isScanning = true
    @State private var isTorchOn = false
    @State private var shouldRescan = false

    @State private var code:String? = nil
    @EnvironmentObject private var manager:AppManager
    @Default(.limitScanningArea) var limitScanningArea
    var response: (String)async-> Void
    
    var config: QRScannerSwiftUIView.Configuration{
        .init(focusImage: nil,
              focusImagePadding: nil,
              animationDuration: nil,
              scanningAreaLimit: limitScanningArea,
              metadataObjectTypes: [.qr, .aztec, .microQR, .dataMatrix])
    }
    

    
    var body: some View {
        ZStack{
            QRScannerSwiftUIView(
                configuration: config,
                isScanning: $isScanning,
                torchActive: $isTorchOn,
                shouldRescan: $shouldRescan,
                onSuccess: { code in
                    AudioManager.tips(.qrcode)
                    Task{@MainActor in
                        try await Task.sleep(for: .seconds(0.5))
                        self.code = code
                        await response(code)
                    }
                },
                onFailure: { error in
                    AudioServicesPlaySystemSound(1053)
                    switch error{
                    case .unauthorized(let status):
                        if status != .authorized{
                            Toast.info(title:  "没有相机权限")
                        }
                    default:
                        Toast.error(title: "扫码失败")
                    }
                    self.code = nil
                },
                onTorchActiveChange: { isOn in
                    isTorchOn = isOn
                }
            )
         

            VStack{
                HStack{
                    
                    Spacer()
                    Button{
                        self.dismiss()
                        Haptic.impact()
                    }label: {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                            .padding()
                            .background26(.ultraThinMaterial, radius: 10)
                            .clipShape(Circle())
                    }
				}
				.padding()
				.padding(.top,50)
				Spacer()
                
                Group{
                    if let code = code{
                        VStack{
                            Menu{
                                Section{
                                    Button(role: .destructive) {
                                        self.shouldRescan.toggle()
                                        self.code = nil
                                    } label: {
                                        Label("重新扫码", systemImage: "qrcode.viewfinder")
                                    }
                                }
                                
                                
                                if let url = URL(string: code), code.contains("://"){
                                    Section{
                                        Button{
                                            self.dismiss()
                                            AppManager.openUrl(url: url)
                                        }label: {
                                            Label("打开地址", systemImage: "link.circle")
                                        }
                                    }
                                }
                                
                                Section{
                                    Button{
                                        self.dismiss()
                                        AppManager.shared.sheetPage = .quickResponseCode(text: code, title: String("二维码"), preview: String("二维码"))
                                    }label: {
                                        Label("生成二维码", systemImage: "qrcode")
                                    }
                                }
                                
                                
                                
                               
                                
                            }label: {
                                Text(verbatim: code)
                                    .tint(.accent)
                                    .lineLimit(1)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                                    .padding()
                                    .background26(.ultraThinMaterial, radius: 10)
                            }
                            
                        }
                    }else{
                        VStack{
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 35))
                                .symbolRenderingMode(.palette)
                                .symbolEffect(.replace)
                                .padding()
                                .contentShape(Rectangle())
                                .if(true){ view in
                                    Group{
                                        if isTorchOn{
                                            view
                                                .foregroundStyle(Color.black)
                                                .background( Circle().fill(.white))
                                        }else{
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
                } .padding(.bottom,80)
                
               

			}

		}
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .global)
                .onChanged({ active in
                    Haptic.selection()
                })
                .onEnded({ action in
                   
                    if  action.translation.height > 100{
                        manager.fullPage = .none
                        Haptic.impact()
                    }
                })
        )
	}


}




#Preview {
    ScanView(){_ in }
}




