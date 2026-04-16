import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct OverdubberApp: App {
    let modelContainer: ModelContainer
    @State private var themeManager = ThemeManager()
    @State private var purchaseManager: PurchaseManager
    @State private var adManager: AdManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        let pm = PurchaseManager()
        _purchaseManager = State(initialValue: pm)
        _adManager = State(initialValue: AdManager(purchaseManager: pm))

        do {
            let schema = Schema([Project.self, Layer.self])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RecorderView()
                .environment(themeManager)
                .environment(purchaseManager)
                .environment(adManager)
                .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
                    OnboardingView()
                }
        }
        .modelContainer(modelContainer)
    }
}
