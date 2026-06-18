//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - GlassmorphicProfileCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:14.
    
import SwiftUI

struct GlassmorphicProfileCard: View {
    @State private var isLiked = false
    
    var body: some View {
        ZStack {
            // 背景炫彩炫光（模拟流体渐变背景）
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: -80, y: -60)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 180, height: 180)
                    .blur(radius: 50)
                    .offset(x: 90, y: 50)
            }
            .opacity(0.6)
            
            // 卡片主体
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // 头像 (带渐变边框)
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .resizable()
                        .symbolRenderingMode(.multicolor)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(.white.opacity(0.1)))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [.white.opacity(0.6), .clear, .purple.opacity(0.3)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sarah Connor")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("@creative_sarah")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // 关注状态标签
                    Text("已认证")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.purple.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Text("三维视觉设计师 & 独立开发者。终身学习者，探索科技与美学的无限交界处。")
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 底部数据栏
                HStack {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("12.5k")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("关注者")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("380")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("创作")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 互动按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            isLiked.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .primary)
                            Text(isLiked ? "已赞" : "点赞")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            // 核心：使用 Apple iOS 15 后的超薄毛玻璃材质
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        }
        .padding()
    }
}

#Preview{
    GlassmorphicProfileCard()
}
