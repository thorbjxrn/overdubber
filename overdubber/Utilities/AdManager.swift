import Foundation
import GoogleMobileAds
import UIKit

@Observable
@MainActor
final class AdManager {
    #if DEBUG
    private static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    private static let interstitialAdUnitID = "ca-app-pub-3919813110479769/6042194583"
    #endif

    private(set) var interstitialAd: InterstitialAd?

    @ObservationIgnored
    private static let appOpenCountKey = "adManager_appOpenCount"
    @ObservationIgnored
    private static let exportCountKey = "adManager_exportCount"

    private static let gracePeriodOpens = 5
    private static let interstitialFrequency = 3

    var appOpenCount: Int {
        didSet {
            UserDefaults.standard.set(appOpenCount, forKey: Self.appOpenCountKey)
        }
    }

    private(set) var exportCount: Int {
        didSet {
            UserDefaults.standard.set(exportCount, forKey: Self.exportCountKey)
        }
    }

    var isInGracePeriod: Bool {
        appOpenCount <= Self.gracePeriodOpens
    }

    var shouldShowBanner: Bool {
        !purchaseManager.isPremium && !isInGracePeriod
    }

    func onExport() -> Bool {
        guard !purchaseManager.isPremium else { return false }
        guard !isInGracePeriod else { return false }
        exportCount += 1
        return exportCount % Self.interstitialFrequency == 0
    }

    @ObservationIgnored
    let purchaseManager: PurchaseManager

    init(purchaseManager: PurchaseManager) {
        self.purchaseManager = purchaseManager
        self.exportCount = UserDefaults.standard.integer(forKey: Self.exportCountKey)
        self.appOpenCount = UserDefaults.standard.integer(forKey: Self.appOpenCountKey)
        self.appOpenCount += 1

        if !isInGracePeriod {
            loadInterstitial()
        }
    }

    func loadInterstitial() {
        guard !purchaseManager.isPremium else { return }

        Task { @MainActor in
            do {
                interstitialAd = try await InterstitialAd.load(
                    with: Self.interstitialAdUnitID,
                    request: AdManagerRequest()
                )
            } catch {
                print("AdManager: Failed to load interstitial: \(error.localizedDescription)")
                interstitialAd = nil
            }
        }
    }

    func showInterstitialIfReady() {
        guard interstitialAd != nil else { return }
        guard !purchaseManager.isPremium else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        interstitialAd?.present(from: topVC)
        interstitialAd = nil
        loadInterstitial()
    }
}
