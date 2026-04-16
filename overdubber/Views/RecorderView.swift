import SwiftUI
import SwiftData

struct RecorderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var theme
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(AdManager.self) private var adManager
    @State private var viewModel: RecorderViewModel?
    @State private var showMixer = false
    @State private var showLibrary = false
    @State private var showExport = false
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact layer waveforms (tap to open mixer)
                if let vm = viewModel, !vm.sortedLayers.isEmpty {
                    Button { showMixer = true } label: {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 4) {
                                ForEach(vm.sortedLayers) { layer in
                                    layerWaveformRow(layer: layer, vm: vm)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                // Live waveform during recording
                if let vm = viewModel, vm.isRecording {
                    WaveformView(samples: vm.liveWaveformSamples, color: theme.current.waveform)
                        .frame(height: 44)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer(minLength: 4)

                // Duration display
                Text(formattedDuration)
                    .font(.system(size: 44, weight: .light, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .padding(.bottom, 12)

                // Record button
                RecordButton(
                    isRecording: viewModel?.isRecording ?? false,
                    action: toggleRecording,
                    recordColor: theme.current.record
                )

                // Status text
                Text(statusText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                Spacer(minLength: 4)

                // Transport controls
                VStack(spacing: 10) {
                    HStack(spacing: 40) {
                        Button(action: { viewModel?.togglePlayback() }) {
                            Image(systemName: viewModel?.isPlaying == true ? "stop.fill" : "play.fill")
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .disabled(viewModel?.layerCount == 0 || viewModel?.isRecording == true)

                        Button(action: { showMixer = true }) {
                            Image(systemName: "slider.vertical.3")
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .disabled(viewModel?.layerCount == 0 || viewModel?.isRecording == true)
                    }

                    // Layer indicator
                    if let layerCount = viewModel?.layerCount, layerCount > 0 {
                        HStack(spacing: 6) {
                            ForEach(0..<layerCount, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.current.accent.opacity(i == layerCount - 1 ? 1.0 : 0.4))
                                    .frame(width: 20, height: 6)
                            }
                        }
                        .animation(.easeOut(duration: 0.3), value: layerCount)
                    }
                }
                .padding(.bottom, 8)

                if adManager.shouldShowBanner {
                    BannerAdView()
                        .frame(height: 50)
                }
            }
            .navigationTitle(viewModel?.currentProject?.name ?? "Overdubber")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button { showLibrary = true } label: {
                            Image(systemName: "folder")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showExport = true } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(viewModel?.layerCount == 0 || viewModel?.isRecording == true)

                        Button { viewModel?.newProject() } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(viewModel?.isRecording == true)
                    }
                }
            }
            .alert("Error", isPresented: showError, presenting: viewModel?.errorMessage) { _ in
                Button("OK") { viewModel?.errorMessage = nil }
            } message: { message in
                Text(message)
            }
            .sheet(isPresented: $showMixer) {
                if let vm = viewModel {
                    MixerView(viewModel: vm)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showLibrary) {
                LibraryView { project in
                    viewModel?.loadProject(project)
                }
            }
            .sheet(isPresented: $showExport) {
                if let vm = viewModel {
                    ExportView(
                        projectName: vm.currentProject?.name ?? "Untitled",
                        layers: vm.exportLayerData
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(purchaseManager: purchaseManager)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RecorderViewModel(modelContext: modelContext)
            }
        }
    }

    private func layerWaveformRow(layer: Layer, vm: RecorderViewModel) -> some View {
        HStack(spacing: 8) {
            Text("\(layer.sortOrder + 1)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            if let samples = vm.layerWaveforms[layer.id], !samples.isEmpty {
                WaveformView(samples: samples, color: theme.current.waveform.opacity(0.6))
                    .frame(height: 24)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 24)
            }
        }
    }

    private var statusText: String {
        guard let vm = viewModel else { return "" }
        if vm.isRecording && vm.layerCount > 0 {
            return "OVERDUBBING • Layer \(vm.layerCount + 1)"
        } else if vm.isRecording {
            return "RECORDING • Layer 1"
        } else if vm.isPlaying {
            return "PLAYING • \(vm.layerCount) layers"
        } else if vm.layerCount > 0 {
            return "\(vm.layerCount) layer\(vm.layerCount == 1 ? "" : "s") • tap record to overdub"
        }
        return "tap record to start"
    }

    private var showError: Binding<Bool> {
        Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.errorMessage = nil } }
        )
    }

    private var formattedDuration: String {
        let duration = viewModel?.recordingDuration ?? 0
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    private func toggleRecording() {
        guard let viewModel else { return }
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            let freeLayerLimit = 4
            if !purchaseManager.isPremium && viewModel.layerCount >= freeLayerLimit {
                showPaywall = true
            } else {
                viewModel.startRecording()
            }
        }
    }
}

#Preview {
    RecorderView()
        .modelContainer(for: [Project.self, Layer.self], inMemory: true)
        .environment(ThemeManager())
}
