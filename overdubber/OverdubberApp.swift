import SwiftUI
import SwiftData

@main
struct OverdubberApp: App {
    let modelContainer: ModelContainer
    @State private var themeManager = ThemeManager()

    init() {
        do {
            let schema = Schema([Project.self, Layer.self])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RecorderView()
                .environment(themeManager)
        }
        .modelContainer(modelContainer)
    }
}
