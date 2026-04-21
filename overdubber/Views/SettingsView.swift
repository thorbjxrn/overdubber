import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    var purchaseManager: PurchaseManager
    var viewModel: RecorderViewModel?

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel?.inputMonitoringEnabled ?? false },
                        set: { viewModel?.inputMonitoringEnabled = $0 }
                    )) {
                        Label("Input Monitoring", systemImage: "headphones")
                    }

                    Toggle(isOn: Binding(
                        get: { viewModel?.mutePlaybackWhileRecording ?? false },
                        set: { viewModel?.mutePlaybackWhileRecording = $0 }
                    )) {
                        Label("Mute Playback While Recording", systemImage: "speaker.slash")
                    }

                } header: {
                    Text("Recording")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel?.tapeWarmthEnabled ?? false },
                        set: { viewModel?.tapeWarmthEnabled = $0 }
                    )) {
                        Label("Tape Warmth", systemImage: "waveform.path")
                    }
                } header: {
                    Text("Effects")
                } footer: {
                    Text("Adds subtle analog saturation, compression, and high-end rolloff — baked in, like real tape.")
                }

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

                    Button {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
                        let device = UIDevice.current.model
                        let ios = UIDevice.current.systemVersion
                        let subject = "Overdubber Bug Report"
                        let body = "\n\n---\nApp: \(version) (\(build))\nDevice: \(device)\niOS: \(ios)"

                        let mailto = "mailto:app.chair433@passfwd.com?subject=\(subject)&body=\(body)"
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: mailto) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Report a Bug", systemImage: "ladybug")
                    }
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
