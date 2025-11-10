//
//  MediumSizedWidget.swift
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


struct MediumSizedWidget: View {
    var entry: Provider.Entry
    let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]
    var body: some View {
       
        ZStack(alignment: .topTrailing){
            
            Image("nolet")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.accent)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 35)
            
            VStack(alignment: .leading){
                Button(intent: RefreshButtonIntent()) {
                    HStack(alignment: .bottom){
                        VStack(alignment: .leading) {
                            Text(entry.result.medium?.title ?? "")
                                .font(.title3.bold())
                                .padding(.bottom, 2)
                                .minimumScaleFactor(0.8)
                            Text(entry.result.medium?.subTitle ?? "")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(2)
                        Spacer()
                    }
                   
                }.buttonStyle(.plain)
                   
                
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(Array(entry.result.medium?.result?.enumerated() ?? [].enumerated() ), id: \.element) { index, item in
                        
                        HStack(alignment: .center){
                            Circle()
                                .fill(titleColor(index: index))
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.footnote.bold())
                                .foregroundStyle(.gray.opacity(0.8))
                                .minimumScaleFactor(0.8)
                            
                            HStack{
                                Spacer(minLength: 0)
                                Text(item.body)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(2)
                        .overlay(alignment: .bottom){
                            if index < 4{
                                Rectangle()
                                    .fill(.gray.opacity(0.2))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
            }
           
        }
    }
    
    func titleColor(index: Int) -> Color {
        let colors: [Color] = [.red, .green, .yellow, .blue, .orange, .cyan]
        return colors[index % colors.count]
    }
}
