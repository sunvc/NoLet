//
//  LockScreenWidget.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/7.
//

import SwiftUI


struct LockScreenWidget:View {
    var entry: Provider.Entry
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("nolet")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 20)
                
            HStack{
                VStack(alignment: .leading) {
                   
                    Text(entry.result.lock?.title ?? "")
                        .font(.caption2)
                        .lineLimit(1)
                    Text(entry.result.lock?.subTitle ?? "")
                        .font(.callout)
                        .lineLimit(1)
                        
                }
                Spacer()
            } .containerRelativeFrame(.horizontal)
        }
        
    }
}
