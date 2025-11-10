//
//  PushIntent.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import AppIntents

struct EasyPushIntent: AppIntent {
    
    static var title: LocalizedStringResource = "快速通知"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "服务器", optionsProvider: ServerAddressProvider())
    var address: String

    
    @Parameter(title: "内容")
    var body: String
    

    static var parameterSummary: some ParameterSummary {
        Summary("将 \(\.$body) 推送给 \(\.$address)")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        
        guard let address = URL(string: address) else {
            throw "Invalid URL"
        }
        
        let res:APIPushToDeviceResponse? = try await NetworkManager()
            .fetch( url: address.absoluteString,
                    method: .POST,
                    params: ["body": body])
        
        
        return .result(value: res?.code == 200)
    }
    
    
}

