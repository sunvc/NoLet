//
//  AddOrChangeChatAccount.swift
//  pushback
//
//  Created by lynn on 2025/5/4.
//
import SwiftUI
import Defaults



struct AddOrChangeChatAccount:View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatManager:openChatManager
    @State private var data: AssistantAccount
    @Default(.assistantAccouns) var assistantAccouns
    @State private var isSecured:Bool = true
    @State private var isTestingAPI = false
    @State private var isAdd:Bool = false
    var title:String
    
    @State private var buttonState:AnimatedButton.buttonState = .normal
    
    init(assistantAccount: AssistantAccount,isAdd:Bool = false) {
        self._data = State(wrappedValue: assistantAccount)
        self.isAdd = isAdd
        if isAdd{
            self.title = String(localized: "增加新资料")
        }else{
            self.title = String(localized: "修改资料")
        }
    }
    
    var body: some View {
        NavigationStack{
            List{
                
                Section("输入别名") {
                    baseNameField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section("请求地址(api.openai.com)") {
                    baseHostField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                Section("请求路径: /v1") {
                    basePathField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section("模型名称: (gpt-4o-mini)") {
                    baseModelField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section("请求密钥") {
                    apiKeyField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                
                Section{
                    HStack{
                        Spacer()
                        AnimatedButton(state:$buttonState, normal:
                                .init(title: String(localized: "测试后保存"),background: .blue,symbolImage: "person.crop.square.filled.and.at.rectangle"), success:
                                .init(title: String(localized: "测试/保存成功"), background: .green,symbolImage: "checkmark.circle"), fail:
                                .init(title: String(localized: "连接失败"),background: .red,symbolImage: "xmark.circle"), loadings: [
                                    .init(title: String(localized: "测试中..."), background: .cyan)
                                ]) { view in
                                    await view.next(.loading(1))
                                    
                                    data.trimAssistantAccountParameters()
                                    
                                    if data.key.isEmpty || data.host.isEmpty || isTestingAPI{
                                        try? await Task.sleep(for: .seconds(1))
                                        await view.next(.fail)
                                        return
                                    }
                                    
                                    self.isTestingAPI = true
                                    let success = await chatManager.test(account: data)
                                    
                                    await view.next(success ? .success : .fail)
                                    await MainActor.run{
                                        self.isTestingAPI = false
                                    }
                                    if success{
                                        await MainActor.run{
                                            self.saveOrChangeData()
                                        }
                                    }
                                }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                
            }
           
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.dismiss()
                    } label: {
                        Text("取消")
                    }.tint(.red)
                        .disabled(isTestingAPI)
                }
                
                if let config = data.toBase64() {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            Haptic.impact()
                            self.dismiss()
                            let local = PBScheme.pb.scheme(host: .assistant, params: ["text":config])
                            DispatchQueue.main.async{
                                AppManager.shared.sheetPage = .quickResponseCode(text: local.absoluteString, title: String(localized: "智能助手"), preview: String(localized: "智能助手"))
                            }
                        }label:{
                            Label("分享", systemImage: "qrcode")
                        }
                    }
                }
            }
            .disabled(isTestingAPI)
        }
    }
    
    private func saveOrChangeData(){
        data.trimAssistantAccountParameters()
       
        if data.host.isEmpty || data.key.isEmpty || data.model.isEmpty {
            Toast.info(title: "参数不能为空")
            return
        }
        
        if assistantAccouns.count == 0{
            data.current = true
        }
        
        
        if let index = assistantAccouns.firstIndex(where: {$0.id == data.id}){
            
            assistantAccouns[index] = data
            Toast.success(title: "添加成功")
            self.dismiss()
            return
        }else{
            
            
            if assistantAccouns.filter({$0.host == data.host && $0.basePath == data.basePath && $0.model == data.model && $0.key == data.key}).count > 0 {
                Toast.error(title: "重复数据")
                return
            }
            
            assistantAccouns.insert(data, at: 0)
            Toast.success(title:"修改成功")
            self.dismiss()
        }
        
        
       
        
    }
    
    private var apiKeyField: some View {
        HStack {
            if isSecured {
                SecureField("API Key", text: $data.key)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .customField(
                        icon: "key.icloud"
                    )
            } else {
                TextField("API Key", text: $data.key)
                    .textContentType(.none)
                    .autocapitalization(.none)
                    .customField(
                        icon: "key.icloud"
                    )
            }
            
            Image(systemName: isSecured ? "eye.slash" : "eye")
                .foregroundColor(isSecured ? .gray : .primary)
                .onTapGesture {
                    isSecured.toggle()
                    Haptic.impact()
                }
        }
    }
    
    private var baseNameField: some View {
        TextField("Name", text: $data.name)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "atom"
            )
    }
    
    private var baseHostField: some View {
        TextField("Host", text: $data.host)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "network"
            )
    }
    
    private var basePathField: some View {
        TextField("BasePath", text: $data.basePath)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "point.filled.topleft.down.curvedto.point.bottomright.up"
            )
    }
    
    private var baseModelField: some View {
        TextField("Model", text: $data.model)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(icon: "slider.horizontal.2.square.badge.arrow.down")
    }
    
  
}

