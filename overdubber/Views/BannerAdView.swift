import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174"
    #else
    private let adUnitID = "ca-app-pub-3919813110479769/6146970514"
    #endif

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let viewWidth = windowScene.windows.first?.frame.width ?? UIScreen.main.bounds.width
            bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
            bannerView.rootViewController = windowScene.windows.first?.rootViewController
        }

        bannerView.load(AdManagerRequest())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
