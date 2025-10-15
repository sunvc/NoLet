//
//  SpeakSettingsView.swift
//  pushback
//
//  Created by lynn on 2025/5/14.
//
import SwiftUI
import Defaults

struct SpeakSettingsView:View {
    @Default(.ttsConfig) var voiceConfig
  
    @Default(.voiceList) var voiceList
    
    @Default(.voicesAutoSpeak) var voicesAutoSpeak
    @Default(.voicesViewShow) var voicesViewShow
    @EnvironmentObject private var manager:AppManager
    
    var groupedVoices: [String: [VoiceManager.MicrosoftVoice]] {
        if searchText.isEmpty {
            return Dictionary(grouping: voiceList, by: { $0.locale })
        } else {
            let query = searchText.lowercased()

            let results = voiceList.filter { voice in
                voice.displayName.lowercased().contains(query)
                || voice.localName.lowercased().contains(query)
                || voice.shortName.lowercased().contains(query)
                || voice.gender.lowercased().contains(query)
                || voice.locale.lowercased().contains(query)
                || voice.localeName.lowercased().contains(query)
            }

            return Dictionary(grouping: results, by: { $0.locale })
        }
    }

    
    @State private var showVoiceSelect:Bool = false
    @State private var showFormatSelect:Bool = false
    @State private var searchText:String = ""
    var body: some View {
        Form{
            
            Section {
                Toggle(isOn: $voicesViewShow) {
                    Label("开启语音", systemImage: voicesViewShow ? "lock.open.display" : "lock.display")
                        .symbolEffect(.replace)
                }
                Toggle(isOn: $voicesAutoSpeak) {
                    Label("自动播放", systemImage: "memories")
                }
            }header:{
                Text("下拉自动播放语音")
            }
            .textCase(.none)
            
            
            Section {
                baseRegionField
            }header: {
                Text("语音服务区域")
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            
            Section{
                baseVoiceField
                    .VButton( onRelease: { _ in
                        self.showVoiceSelect.toggle()
                        self.hideKeyboard()
                        return true
                    })
            }header: {
                Text("默认语音")
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            Section {
                HStack{
                    Text(verbatim: "-100")
                    Slider(value:Binding(get: {
                        Double(voiceConfig.defaultRate)
                    }, set: { value in
                        voiceConfig.defaultRate = Int(value)
                    }) , in: -100...100)
                    Text(verbatim: "100")
                }
                .onChange(of: voiceConfig.defaultRate) { _ in
                    Haptic.impact(.light, limitFrequency: true)
                }
            } header: {
                HStack{
                    Text("默认语速")
                    Spacer()
                    Text(verbatim: "\(voiceConfig.defaultRate)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                   
                }
            }
            .textCase(.none)
            .listRowSpacing(0)
            
            
            Section {
                HStack{
                    Text(verbatim: "-100")
                    Slider(value: Binding(get: {
                        Double(voiceConfig.defaultPitch)
                    }, set: { value in
                        voiceConfig.defaultPitch = Int(value)
                    }), in: -100...100)
                    Text(verbatim:"100")
                }
                .onChange(of: voiceConfig.defaultPitch) { _ in
                    Haptic.impact(.light,limitFrequency: true)
                }
            } header: {
               HStack{
                   Text("默认语调")
                   Spacer()
                   Text(verbatim: "\(voiceConfig.defaultPitch)")
                       .font(.body)
                       .fontWeight(.bold)
                       .foregroundStyle(.blue)
                  
               }
           }
            .textCase(.none)
            .listRowSpacing(0)
            
            Section {
                baseFormatField
                    .VButton(onRelease: {_ in
                        showFormatSelect.toggle()
                        return true
                    })
            }header: {
                Text("默认音频格式")
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
        }
        .navigationTitle("语音配置")
        .sheet(isPresented: $showVoiceSelect) { VoiceSelectView() }
        .sheet(isPresented: $showFormatSelect) {
            NavigationStack{
                Picker("选择格式", selection: $voiceConfig.defaultFormat) {
                    ForEach(VoiceManager.AudioFormat.allCases, id: \.rawValue) { item in
                        Text(verbatim: "\(item.rawValue)")
                            .foregroundStyle(voiceConfig.defaultFormat == item ? .green : .gray)
                            .tag(item)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("默认音频格式")
                .navigationBarTitleDisplayMode(.inline)
            }.presentationDetents([.height(300)])
               
        }
        .toolbar {
            ToolbarItem{
                Button{
                    guard !manager.speaking else { return }
                    Task.detached(priority: .userInitiated) {
                        guard let player = await AudioManager.shared.speak(String(localized: "欢迎使用 \(BaseConfig.AppName)"),noCache: true) else {
                            return
                        }
                        player.play()
                        Haptic.impact(.light)
                        
                    }
                }label:{
                    Label("试听", systemImage: manager.speaking ? "livephoto.play" : "play.circle")
                        .animation(.default, value: manager.speaking)
                }
            }
        }
        
    }
    
    @ViewBuilder
    func VoiceSelectView() -> some View{
        NavigationStack{
            ScrollViewReader {  proxy in
                ScrollView{
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedVoices.keys.sorted(), id: \.self ){locale in
                            
                            Section {
                                ForEach(groupedVoices[locale]!,id: \.id){ item in
                                    HStack{
                                        Text(verbatim: "\(item.localName)")
                                            .padding(.horizontal)
                                            .fontWeight(item.shortName == voiceConfig.defaultVoice ? .bold : .light)
                                        Text(verbatim: "(\(item.gender))")
                                        Spacer()
                                        Button {
                                            voiceConfig.defaultVoice = item.shortName
                                            self.showVoiceSelect.toggle()
                                            Haptic.impact()
                                        }label:{
                                            Image(systemName: "cursorarrow.click")
                                                .imageScale(.large)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        item.shortName == voiceConfig.defaultVoice ? Color.green : Color.gray.opacity(0.1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.horizontal)
                                    
                                    .id(item.shortName)
                                
                                    
                                    
                                }
                            } header: {
                                HStack{
                                    Spacer()
                                    Text(locale)
                                        .fontWeight(.black)
                                        .padding(.trailing)
                                        .foregroundStyle(Color.accentColor)
                                        .blendMode(.difference)
                                }
                            }
                            
                            
                        }
                    }
                    if voiceList.count == 0{
                        ProgressView {
                            Label("加载中", systemImage: "ellipsis")
                        }
                    }
                }
                .onAppear{
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                    }
                }
                .task(priority: .background, {
                    do{
                        let client = try VoiceManager()
                        _ = try await client.listVoices()
                        withAnimation {
                            proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                        }
                    }catch{
                        NLog.error(error)
                    }
                })
                .navigationTitle("选择语音模型")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Image(systemName: "gobackward")
                            .VButton(onRelease: {_ in
                                Defaults.reset(.voiceList)
                                Task.detached(priority: .userInitiated) {
                                    let client = try VoiceManager()
                                    _ = try await client.listVoices()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                        withAnimation {
                                            proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                                        }
                                    }
                                }
                                
                                return true
                            })
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Image(systemName: "pin.fill")
                            .VButton(onRelease: {_ in
                                withAnimation {
                                    proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                                }
                                return true
                            })
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        
        }
    }
    
    private var baseRegionField: some View {
        TextField("Region", text: $voiceConfig.region)
            .autocapitalization(.none)
            .customField(
                icon: "atom", false
            )
    }
    
    private var baseVoiceField: some View {
        TextField("Voice", text: $voiceConfig.defaultVoice)
            .autocapitalization(.none)
            .disabled(true)
            .customField(
                icon: "speaker.wave.2.bubble.left", false
            )
    }
    
    
    
    private var baseFormatField: some View {
        TextField("Format", text: Binding(get: {  voiceConfig.defaultFormat.rawValue }, set: { _ in}))
            .autocapitalization(.none)
            .disabled(true)
            .customField(
                icon: "paintbrush", false
            )
    }
    
    
}
