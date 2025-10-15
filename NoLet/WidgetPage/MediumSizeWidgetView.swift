//
//  MediumSizeWidgetView.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//

import SwiftUI


struct MediumSizedWidget: View {
    var result:WidgetData
    let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]
    var body: some View {
       
        ZStack(alignment: .topTrailing){
            
            Image("nolet")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.accent)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 35)
            
            VStack{
                HStack(alignment: .bottom){
                    VStack(alignment: .leading) {
                        Text(result.medium?.title ?? "")
                            .font(.title3.bold())
                            .padding(.bottom, 2)
                        Text(result.medium?.subTitle ?? "")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    .padding(2)
                    Spacer()
                }
                
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(Array(result.medium?.result?.enumerated() ?? [].enumerated()), id: \.element) { index, item in
                        
                        HStack(alignment: .center){
                            Circle()
                                .fill(titleColor(index: index))
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.footnote.bold())
                                .foregroundStyle(.gray.opacity(0.8))
                            
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
        .frame(width: 300, height: 150)
        .padding()
        .background26(.widget, radius: 20)
    }
    
    func titleColor(index: Int) -> Color {
        let colors: [Color] = [.red, .green, .yellow, .blue, .orange, .cyan]
        return colors[index % colors.count]
    }
}
