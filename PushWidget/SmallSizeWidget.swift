//
//  SmallSizeWidget.swift
//  NoLet
//
//  Created by lynn on 2025/5/7.
//

import SwiftUI

struct SmallSizeWidget: View {
    var entry: Provider.Entry
    var body: some View {
        VStack{
            Spacer(minLength: 0)
            Button(intent: RefreshButtonIntent()) {
                HStack{
                    
                    Text(entry.result.small?.title ?? "")
                        .font(.title3.bold())
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                }
            }.buttonStyle(.plain)
            .padding(.bottom, 10)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            HStack{
                Image("nolet")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width:15, height: 15)
                    .foregroundStyle(.green)
                   
                Text(entry.result.small?.result?[0].name ?? "")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                HStack{
                    Spacer()
                    Text(entry.result.small?.result?[0].body ?? "")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
               
                    
            }
            .padding(.bottom, 10)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            HStack{
                VStack{
                    HStack{
                        Image("logo")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width:15, height: 15)
                            .foregroundStyle(.blue)
                            
                        Text(entry.result.small?.result?[1].name ?? "")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .minimumScaleFactor(0.5)
                        Spacer()
                    }
                    Text(entry.result.small?.result?[1].body ?? "")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.5)
                }
              
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.gray.opacity(0.2))
                    .padding(.horizontal, 1)
                
                VStack{
                    HStack{
                        
                        Image("logo")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width:15, height: 15)
                            .foregroundStyle(.red)
                        
                        Text(entry.result.small?.result?[2].name ?? "")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .minimumScaleFactor(0.5)
                        Spacer()
                        
                    }
                    HStack{
                        Text(entry.result.small?.result?[2].body  ?? "")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.5)
                    }
                   
                }
            }
        }
    }
}
