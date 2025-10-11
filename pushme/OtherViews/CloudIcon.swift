//
//  CloudIcon.swift
//  pushback
//
//  Created by lynn on 2025/3/18.
//

import SwiftUI
import Defaults
import CloudKit
import UniformTypeIdentifiers
import PhotosUI
import Foundation

struct CloudIcon: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager:AppManager
    
    @State private var searchText:String = ""
    
    @State private var icons:[CKRecord] = []
    
    @State private var loading = false
    
    @State private var selectImage:UIImage?
    
    @State private var offset: CGSize = .zero
    
    @State private var isTargeted = false
    
    @State private var dropImage:PushIcon?
    
    @State private var rotation: Double = 0
    @State private var selectItem: PhotosPickerItem? = nil
 
    var body: some View {
        NavigationStack{
            VStack{
                if let item = dropImage{
                    UploadIclondIcon(pushIcon: item) { icon in
                        if let icon = icon.toRecord(recordType: "PushIcon"){
                            icons.append(icon)
                        }
                        self.dropImage = nil
                    } endEditing: {
                        self.hideKeyboard()
                    }
                }else{
                    ScrollView(.vertical, showsIndicators: false){
                        
                        if  ProcessInfo.processInfo.isiOSAppOnMac{
                            VStack{
                                Text("拖动图片到此处")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.accentColor)
                                    .multilineTextAlignment(.center)  // 使文字居中
                                    .lineSpacing(10)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .blur(radius: loading ? 5 : 0)
                        }
                        
                        if icons.count > 0{
                            
                            VStack{
                                TagLayout(alignment: .center, spacing: 10) {
                                    ForEach(icons, id: \.recordID){ icon in
                                        
                                        if let name = icon["name"] as? String{
                                            
                                            Menu{
                                                Button {
                                                    if let icon = icon.toPushIcon() {
                                                        withAnimation {
                                                            self.selectImage = icon.previewImage
                                                        }
                                                        
                                                    }else {
                                                        Toast.error(title: "图片加载失败")
                                                    }
                                                    
                                                }label:{
                                                    
                                                    Label("查看图标", systemImage: "photo.artframe.circle")
                                                        .customForegroundStyle(.accent, .primary)
                                                }
                                                
                                                Button {
                                                    Clipboard.set(name)
                                                    Toast.copy(title: "复制成功")
                                                }label:{
                                                    
                                                    Label("复制key", systemImage: "doc.on.doc")
                                                        .customForegroundStyle(.accent, .primary)
                                                }
                                                
                                                Section{
                                                    Button(role: .destructive) {
                                                        
                                                        CloudManager.shared.deleteCloudIcon( icon.recordID.recordName) { error in
                                                            if let error{
                                                                Toast.shared.present(title: "\(error.localizedDescription)", symbol: .error, tint: .red)
                                                            }else{
                                                                Toast.success(title: "图片删除成功")
                                                                if let index = icons.firstIndex(where: {$0.recordID.recordName == icon.recordID.recordName}){
                                                                    icons.remove(at: index)
                                                                }
                                                            }
                                                        }
                                                    }label:{
                                                        
                                                        Label("删除云图标", systemImage: "trash")
                                                            .customForegroundStyle(.accent, .primary)
                                                    }
                                                }
                                                
                                                
                                            }label:{
                                                TagView(name, .blue, "cursorarrow.click.2")
                                            }
                                            
                                        }
                                    }
                                    
                                }
                                
                            }
                            .padding(.top )
                            .blur(radius: selectImage == nil ? 0 : 5)
                        }
                        
                    }
                    .onDrop(of: [.image], isTargeted: $isTargeted) { items in
                        
                        if let item = items.first{
                            _ = item.loadDataRepresentation(for: .image) { data, error in
                                
                                guard let data = data else { return }

                                DispatchQueue.main.async {
                                    dropImage = toPushIcon(data)
                                }
                            }
                        }
                        return true
                    }
                    
                }
            }
            
            .overlay{
                if isTargeted{
                    ColoredBorder(top: 5, bottom: ProcessInfo.processInfo.isiOSAppOnMac ? 5 : 50)
                }
            }
            .animation(.smooth, value: icons)
            .navigationTitle("云图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selectItem) {
                        Image(systemName: "photo.circle")
                            .accessibilityLabel("选择图片")
                    }
                }
                
            }
            .overlay{
                if loading {
                    VStack {
                        Spacer()
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(2)
                                .padding()
                            Text("加载中...")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(width: windowWidth)
                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        Spacer()
                    }
                }
            }
            .overlay {
                if let selectImage = selectImage{
                    Image(uiImage: selectImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(height: 350)
                        .padding(.horizontal)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation {
                                        self.offset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    let dragThreshold: CGFloat = 50
                                    let translation = value.translation
                                    
                                    // 判断滑动是否超过阈值
                                    guard abs(translation.width) > dragThreshold || abs(translation.height) > dragThreshold else {
                                        // 滑动距离不够，回弹
                                        withAnimation {
                                            self.offset = .zero
                                        }
                                        return
                                    }
                                    
                                    // 计算滑动方向
                                    var finalOffset = CGSize.zero
                                    let slideDistance: CGFloat = 500
                                    
                                    if abs(translation.width) > abs(translation.height) {
                                        // 水平方向为主
                                        finalOffset = CGSize(width: translation.width > 0 ? slideDistance : -slideDistance, height: 0)
                                    } else {
                                        // 垂直方向为主
                                        finalOffset = CGSize(width: 0, height: translation.height > 0 ? slideDistance : -slideDistance)
                                    }
                                    
                                    // 动画滑出
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        self.offset = finalOffset
                                    }
                                    
                                    // 滑出后清除图片
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        self.selectImage = nil
                                        self.offset = .zero
                                    }
                                }
                        )
                    
                }
            }
            .onAppear{
                withAnimation {
                    self.loading = true
                }
                getIcons()
                
            }
            .onChange(of: selectItem) { newItem in
                
                guard let newItem else{ return }
                self.dropImage = nil
                Task.detached(priority: .userInitiated) {
                    do{
                        if let data = try await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run{
                                dropImage = toPushIcon(data)
                            }
                        }
                        
                    }catch{
                        NLog.error(error.localizedDescription)
                    }
                    await MainActor.run {
                        self.selectItem = nil
                    }
                }
            }
           
        }
    }
    
    
    func getIcons(){
        Task.detached{
            let icons = await CloudManager.shared.queryIconsForMe()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                withAnimation {
                    self.icons = icons
                    self.loading = false
                }
            }
        }
    }
    
    func toPushIcon(_ data: Data)-> PushIcon?{
        if let image = data.toThumbnail(max: 300){
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("cloudIcon.png")
            
            guard let pngData = image.pngData() else { return nil }
            
            do{
                try pngData.write(to: tempURL)
                return PushIcon(id: UUID().uuidString, name: "",
                             description: [], size: pngData.count, sha256: pngData.sha256(), file: tempURL, previewImage: image)
            }catch{
                NLog.error(error.localizedDescription)
            }
            
           
        }
        return nil
    }
    
    /// Tag View
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)
            
            Image(systemName: icon)
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color.gradient)
        }
    }
    
}
