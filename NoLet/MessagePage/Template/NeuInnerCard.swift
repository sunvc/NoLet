//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - NiWuCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/24 07:55.
    

import SwiftUI

// MARK: - 新拟物化颜色扩展
extension Color {
    static let neuBackground = Color(red: 0.88, green: 0.89, blue: 0.93)
    static let neuShadow = Color(red: 0.64, green: 0.69, blue: 0.78)
    static let neuHighlight = Color.white
    static let neuTextPrimary = Color(red: 0.29, green: 0.31, blue: 0.35)
    static let neuTextSecondary = Color(red: 0.47, green: 0.49, blue: 0.53)
    static let neuPurple = Color(red: 0.61, green: 0.35, blue: 0.71)
    static let neuPink = Color(red: 0.91, green: 0.33, blue: 0.49)
    static let neuBlue = Color(red: 0.10, green: 0.53, blue: 0.80)
    static let neuCyan = Color(red: 0.00, green: 0.70, blue: 0.77)
}

// MARK: - 新拟物化阴影修饰符
struct NeuShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .neuShadow.opacity(0.5), radius: 6, x: 4, y: 4)
            .shadow(color: .neuHighlight.opacity(0.8), radius: 6, x: -4, y: -4)
    }
}

struct NeuInnerShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.neuShadow.opacity(0.2), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: 2, y: 2)
                    .mask(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.neuHighlight.opacity(0.7), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: -2, y: -2)
                    .mask(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)))
            )
    }
}

extension View {
    func neuShadow() -> some View {
        self.modifier(NeuShadow())
    }
    
    func neuInnerShadow() -> some View {
        self.modifier(NeuInnerShadow())
    }
}

// MARK: - 圆形头像组件
struct NeuAvatar: View {
    let initial: String
    let gradient: LinearGradient
    
    var body: some View {
        ZStack {
            Circle()
                .fill(gradient)
                .neuShadow()
            
            Text(initial)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - 媒体图片组件
struct NeuMediaImage: View {
    let url: String
    let isVideo: Bool
    let isMore: Bool
    
    var body: some View {
        ZStack {
            if isMore {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.neuBackground)
                    .neuInnerShadow()
                
                VStack(spacing: 4) {
                    Text("12项")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.neuTextPrimary)
                    Text("媒体")
                        .font(.system(size: 10))
                        .foregroundColor(.neuTextSecondary)
                }
            } else {
                AsyncImage(url: URL(string: url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.neuBackground.opacity(0.5))
                    }
                }
                .cornerRadius(12)
                .neuShadow()
                
                if isVideo {
                    Color.black.opacity(0.3)
                        .cornerRadius(12)
                    
                    ZStack {
                        Circle()
                            .fill(Color.neuBackground)
                            .frame(width: 48, height: 48)
                            .neuShadow()
                        
                        Image(systemName: "play.fill")
                            .foregroundColor(.neuTextPrimary)
                            .font(.system(size: 16))
                            .offset(x: 2)
                    }
                    
                    Text("00:42")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.neuTextPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.neuBackground)
                                .neuShadow()
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(8)
                }
            }
        }
        .frame(width: 100, height: 100)
    }
}

// MARK: - 操作按钮组件
struct NeuActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.neuTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.neuBackground)
                    .neuShadow()
            )
        }
    }
}

// MARK: - 完整的新拟物化消息卡片
struct NeumorphicMessageCard: View {
    var body: some View {
        ZStack {
            // 卡片外阴影
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.neuBackground)
                .shadow(color: .neuShadow.opacity(0.4), radius: 16, x: 8, y: 8)
                .shadow(color: .neuHighlight.opacity(0.8), radius: 16, x: -8, y: -8)
            
            VStack(spacing: 0) {
                // MARK: - 顶部区域
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        // Icon - 消息类型图标
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.neuBackground)
                                .frame(width: 48, height: 48)
                                .neuShadow()
                            
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.neuTextSecondary)
                                .font(.system(size: 18))
                        }
                        
                        // 标题和副标题
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("产品设计团队")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.neuTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 时间戳
                                Text("刚刚")
                                    .font(.system(size: 12))
                                    .foregroundColor(.neuTextSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.neuBackground)
                                            .neuInnerShadow()
                                    )
                            }
                            
                            Text("@王小美 分享了图片和视频")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.neuPurple)
                        }
                        
                        // Group - 群组堆叠头像
                        HStack(spacing: -12) {
                            NeuAvatar(initial: "张", gradient: LinearGradient(colors: [.neuPurple, .neuPink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            NeuAvatar(initial: "李", gradient: LinearGradient(colors: [.neuBlue, .neuCyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            ZStack {
                                Circle()
                                    .fill(Color.neuBackground)
                                    .frame(width: 32, height: 32)
                                    .neuShadow()
                                
                                Text("+5")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.neuTextSecondary)
                            }
                        }
                    }
                    
                    // Body - 正文内容
                    Text("大家好！这是新版App的UI设计稿，包含首页、详情页和个人中心。视频里有详细交互动效演示～")
                        .font(.system(size: 15))
                        .foregroundColor(.neuTextSecondary)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
                .padding(20)
                .padding(.bottom, 8)
                
                // MARK: - 媒体区域
                VStack {
                    HStack(spacing: 8) {
                        NeuMediaImage(url: "https://picsum.photos/200/200?random=31", isVideo: false, isMore: false)
                        NeuMediaImage(url: "https://picsum.photos/200/200?random=32", isVideo: false, isMore: false)
                        NeuMediaImage(url: "https://picsum.photos/200/200?random=33", isVideo: true, isMore: false)
                    }
                    HStack(spacing: 8) {
                        NeuMediaImage(url: "https://picsum.photos/200/200?random=34", isVideo: false, isMore: false)
                        NeuMediaImage(url: "https://picsum.photos/200/200?random=35", isVideo: false, isMore: false)
                        NeuMediaImage(url: "", isVideo: false, isMore: true)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.neuBackground)
                        .neuInnerShadow()
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // MARK: - 底部分割线和操作按钮
                Divider()
                    .background(Color.neuShadow.opacity(0.3))
                    .padding(.horizontal, 20)
                
                HStack(spacing: 16) {
                    NeuActionButton(icon: "heart", title: "28")
                    Spacer(minLength: 0)
                    NeuActionButton(icon: "bubble.left", title: "回复")
                    Spacer(minLength: 0)
                    NeuActionButton(icon: "square.and.arrow.up", title: "转发")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
        }
        .padding(4)
        .background(Color.neuBackground)
        .cornerRadius(24)
    }
}

// MARK: - 预览视图
struct NeumorphicMessageCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.neuBackground
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    NeumorphicMessageCard()
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 24)
            }
        }
        .preferredColorScheme(.light)
        .previewDisplayName("新拟物化卡片")
    }
}

// MARK: - 使用示例
struct ContentViewTest: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("消息卡片")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.neuTextPrimary)
                            .padding(.top, 20)
                        
                        NeumorphicMessageCard()
                    }
                    .padding(.horizontal, 16)
                }
                .navigationBarHidden(true)
            }
        }
    }
}

#Preview{
    ContentViewTest()
}
