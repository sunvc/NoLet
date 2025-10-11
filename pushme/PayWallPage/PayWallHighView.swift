//
//  PayWallHighView.swift
//  pushback
//
//  Created by lynn on 2025/5/15.
//

import SwiftUI
import StoreKit

/// IAP View Images
enum IAPImage: String, CaseIterable {
    /// Raw value represents the asset image
    case one = "IAP1"
    case two = "IAP2"
    case three = "IAP3"
    case four = "IAP4"
}

@available(iOS 18.0, *)
struct PayWallHighView: View {
    @State private var loadingStatus: (Bool, Bool) = (false, false)
    @EnvironmentObject private var manager:AppManager
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let isSmalleriPhone = size.height < 700

            VStack(spacing: 0) {

                Group {
                    if isSmalleriPhone {
                        SubscriptionStoreView(productIDs: Self.productIDs, marketingContent: {
                            CustomMarketingView()
                        })
                        .subscriptionStoreControlStyle(.compactPicker, placement: .bottomBar)
                    } else {
                        SubscriptionStoreView(productIDs: Self.productIDs, marketingContent: {
                            CustomMarketingView()
                        })
                        .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
                    }
                }
                .subscriptionStorePickerItemBackground(.ultraThinMaterial)
                .storeButton(.visible, for: .restorePurchases)
                .storeButton(.hidden, for: .policies)
                .onInAppPurchaseStart { product in
                    NLog.log("Show Loading Screen")
                    NLog.log("Purchasing \(product.displayName)")
                }
                .onInAppPurchaseCompletion { product, result in
                    switch result {
                    case .success(let result):
                        switch result {
                        case .success(_):
                            NLog.log("Success and verify purchase using verification result")
                        case .pending:
                            NLog.log("Pending Action")
                        case .userCancelled:
                            NLog.log("User Cancelled")
                        @unknown default:
                            fatalError()
                        }
                    case .failure(let error):
                        NLog.error(error.localizedDescription)
                    }
                    
                    NLog.log("Hide Loading Screen")
                }
                .subscriptionStatusTask(for: "21582431") {
                    if let result = $0.value {
                        let premiumUser = !result.filter({ $0.state == .subscribed }).isEmpty
                        NLog.log("User Subscribed = \(premiumUser)")
                        manager.PremiumUser = premiumUser
                    }
                    
                    loadingStatus.1 = true
                }
                
                /// Privacy Policy & Terms of Service
                HStack(spacing: 3) {
                    Link("用户协议", destination: URL(string: BaseConfig.userAgreement)!)
                    Text("和")
                    Link("隐私政策", destination: URL(string: BaseConfig.privacyURL)!)
                }
                .font(.caption)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isLoadingCompleted ? 1 : 0)
            .background(
                BackdropView()
                    .ignoresSafeArea(.all, edges: .bottom)
            )
            .overlay {
                if !isLoadingCompleted {
                    ProgressView()
                        .font(.largeTitle)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isLoadingCompleted)
            .storeProductsTask(for: Self.productIDs) { @MainActor collection in
                if let products = collection.products, products.count == Self.productIDs.count {
                    try? await Task.sleep(for: .seconds(0.1))
                    loadingStatus.0 = true
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .tint(.white)
        .statusBarHidden()
    }
    
    var isLoadingCompleted: Bool {
        loadingStatus.0 && loadingStatus.1
    }
    
    static var productIDs: [String] {
        return ["pushback_monthly_18_intro7days_free", "pushback_yearly_128_intro7days_free"]
    }
    
    /// Backdrop View
    @ViewBuilder
    func BackdropView() -> some View {
        GeometryReader {
            let size = $0.size
            
            /// This is a Dark image, but you can use your own image as per your needs!
            Image("IAP4")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .scaleEffect(1.5)
                .blur(radius: 70, opaque: true)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.2))
                }
                .ignoresSafeArea()
        }
    }
    
    /// Custom Marketing View (Header View)
    @ViewBuilder
    func CustomMarketingView() -> some View {
        ZStack {
            /// App Screenshots View
            HStack(spacing: 25) {
                ScreenshotsView([.one, .two, .three], offset: -200)
                ScreenshotsView([.four, .one, .two], offset: -350)
                ScreenshotsView([.two, .three, .one], offset: -250)
                    .overlay(alignment: .trailing) {
                        ScreenshotsView([.four, .two, .one], offset: -150)
                            .visualEffect { content, proxy in
                                content
                                    .offset(x: proxy.size.width + 25)
                            }
                    }
            }
            .frame(maxHeight: .infinity)
            .offset(x: 20)
            /// Progress Blur Mask
            .mask {
                LinearGradient(colors: [
                    .white,
                    .white.opacity(0.9),
                    .white.opacity(0.7),
                    .white.opacity(0.4),
                    .clear
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .padding(.bottom, -30)

            }

            /// Replace with your App Information
            VStack(spacing: 6) {

                Text(BaseConfig.AppName)
                    .font(.largeTitle.bold())
                
                Text("Premium 会员")
                    .font(.largeTitle.bold())
                
                Text("Pushback（反推）是一款消息提醒应用程序")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(.top, 30)
            .padding(.bottom, 18)
            .padding(.horizontal, 15)
        }
    }
    
    @ViewBuilder
    func ScreenshotsView(_ content: [IAPImage], offset: CGFloat) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(content.indices, id: \.self) { index in
                    Image(content[index].rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .offset(y: offset)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .rotationEffect(.init(degrees: -30), anchor: .bottom)
        .scrollClipDisabled()
    }
}

@available(iOS 18.0, *)
#Preview {
    PayWallHighView()
        .environmentObject(AppManager.shared)
        .sheet(isPresented: .constant(true)) {
            PayWallHighView()
                .environmentObject(AppManager.shared)
        }
}
