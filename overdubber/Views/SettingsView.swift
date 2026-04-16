import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    var purchaseManager: PurchaseManager

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Premium") {
                    if purchaseManager.isPremium {
                        Label("Premium Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(theme.current.accent)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Premium", systemImage: "star.circle")
                        }
                    }
                }

                Section("Theme") {
                    if purchaseManager.isPremium {
                        themeGrid
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Themes", systemImage: "lock.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }

                #if DEBUG
                Section("Debug") {
                    Button("Toggle Premium") {
                        purchaseManager.debugTogglePremium()
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }

    private var themeGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
            ForEach(AppTheme.allCases) { t in
                Button {
                    withAnimation { theme.current = t }
                } label: {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(t.accent)
                            .frame(width: 40, height: 40)
                            .overlay {
                                if theme.current == t {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }

                        Text(t.rawValue)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
