//
//  SmallSizeWidgetView.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//

import SwiftUI

struct SmallSizeWidgetView: View {
    var result: WidgetData
    var body: some View {
        VStack{
            Spacer(minLength: 0)
            HStack{
                
                Text(result.small?.title ?? "")
                    .font(.title3.bold())
                
                Spacer()
                
            }
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
                   
                Text(result.small?.result?[0].name ?? "")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                HStack{
                    Spacer()
                    Text(result.small?.result?[0].body ?? "")
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
                        Image("nolet")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width:15, height: 15)
                            .foregroundStyle(.blue)
                            
                        Text(result.small?.result?[1].name ?? "")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Text(result.small?.result?[1].body ?? "")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
              
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.gray.opacity(0.2))
                    .padding(.horizontal, 1)
                
                VStack{
                    HStack{
                        
                        Image("nolet")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width:15, height: 15)
                            .foregroundStyle(.red)
                        
                        Text(result.small?.result?[2].name ?? "")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                        
                    }
                    HStack{
                        Text(result.small?.result?[2].body ?? "")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                   
                }
            }
        }
        .frame(width: 150,height: 130)
        .padding()
        .background26(.widget, radius: 20)
    }
}
