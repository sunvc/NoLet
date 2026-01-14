//
//  AppIconView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo 2024/8/10.
//

import Defaults
import SwiftUI
import Kingfisher

struct AppIconView: View {

    @Default(.appIcon) var setting_active_app_icon
    @EnvironmentObject private var manager: AppManager
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(AppIconEnum.allCases, id: \.self) { item in
                            iconItem(item: item)
                                .id(item)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(setting_active_app_icon, anchor: .center)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation {
                                proxy.scrollTo(setting_active_app_icon, anchor: .center)
                            }
                        } label: {
                            Text("程序图标")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            if let icon = AppIconEnum.allCases.first {
                                Image(systemName: "chevron.left.2")
                                    .padding(.horizontal, 10)
                                    .VButton(onRelease: { _ in
                                        withAnimation {
                                            proxy.scrollTo(icon, anchor: .center)
                                        }
                                        return true
                                    })
                                    .accessibilityLabel("滚动到开始")
                                    .accessibilityAddTraits(.isButton)
                            }
                            
                            Image(systemName: "\(AppIconEnum.allCases.count).circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.pink, .gray)
                            
                            if let icon = AppIconEnum.allCases.last {
                                Image(systemName: "chevron.right.2")
                                    .padding(.horizontal, 10)
                                    .VButton(onRelease: { _ in
                                        withAnimation {
                                            proxy.scrollTo(icon, anchor: .center)
                                        }
                                        return true
                                    })
                                    .accessibilityLabel("滚动到结束")
                                    .accessibilityAddTraits(.isButton)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func iconItem(item: AppIconEnum) -> some View {
        Button {
            Haptic.impact()
            setSystemIcon(item)
        } label: {
            ZStack {
                Image(item.logo)
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .frame(width: 200, height: 200)
                    .shadow(radius: 3)
                    .tag(item)
                    .overlay( // 再添加圆角边框
                        ColoredBorder(cornerRadius: 20)
                            .scaleEffect(item == setting_active_app_icon ? 1 : 0.1)
                            .opacity(item == setting_active_app_icon ? 1 : 0)
                    )
            }
            .animation(.interactiveSpring, value: setting_active_app_icon)
            .padding()
            .listRowBackground(Color.clear)
        }
    }

    func setSystemIcon(_ icon: AppIconEnum) {
        let setting_active_app_icon_backup = setting_active_app_icon

        setting_active_app_icon = icon

        let application = UIApplication.shared

        if application.supportsAlternateIcons {
            application.setAlternateIconName(setting_active_app_icon.name) { err in
                if let err {
                    logger.info("\(err)")
                    DispatchQueue.main.async {
                        setting_active_app_icon = setting_active_app_icon_backup
                    }
                }
            }

            Toast.success(title: "切换成功")
            AppManager.shared.open(sheet: nil)
        } else {
            Toast.question(title: "暂时不能切换")
        }
    }
}

#Preview {
    AppIconView()
}
