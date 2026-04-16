import SwiftUI
import SwiftData
import AVFoundation

struct RecorderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(ThemeManager.self) private var theme
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(AdManager.self) private var adManager
    @State private var viewModel: RecorderViewModel?
    @State private var showMixer = false
    @State private var showLibrary = false
    @State private var showExport = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showRename = false
    @State private var renameText = ""
    @State private var showBluetoothWarning = false
    @AppStorage("hasShownBluetoothWarning") private var hasShownBluetoothWarning = false

    private var isRegularWidth: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            Group {
                if isRegularWidth, let vm = viewModel, vm.layerCount > 0 {
                    HStack(spacing: 0) {
                        recorderContent
                            .frame(maxWidth: .infinity)
                        Divider()
                        MixerView(viewModel: vm)
                            .frame(width: 360)
                    }
                } else {
                    recorderContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        renameText = viewModel?.currentProject?.name ?? ""
                        showRename = true
                    } label: {
                        Text(viewModel?.currentProject?.name ?? "Overdubber")
                            .font(.system(.subheadline, design: .monospaced, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .disabled(viewModel?.currentProject == nil)
                }
                toolbarContent
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
                SettingsView(purchaseManager: purchaseManager, viewModel: viewModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
            .alert("Bluetooth Latency", isPresented: $showBluetoothWarning) {
                Button("Record Anyway") {
                    hasShownBluetoothWarning = true
                    viewModel?.startRecording()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Bluetooth audio adds latency that can cause layers to be out of sync. For best results, use wired headphones when overdubbing.")
            }
            .alert("Rename Project", isPresented: $showRename) {
                TextField("Project name", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") { viewModel?.renameProject(renameText) }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RecorderViewModel(modelContext: modelContext)
            }
        }
    }

    private var recorderContent: some View {
        VStack(spacing: 0) {
            if let vm = viewModel, !vm.sortedLayers.isEmpty, !isRegularWidth {
                Button { showMixer = true } label: {
                    ZStack(alignment: .leading) {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 4) {
                                    ForEach(vm.sortedLayers) { layer in
                                        layerWaveformRow(layer: layer, vm: vm)
                                            .id(layer.id)
                                    }
                                }
                            }
                            .onChange(of: vm.layerCount) {
                                if let last = vm.sortedLayers.last {
                                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                                }
                            }
                        }

                        if vm.isPlaying, !vm.isRecording, let project = vm.currentProject, project.duration > 0 {
                            GeometryReader { geo in
                                let progress = vm.playbackPosition / project.duration
                                PlayheadIndicator(color: theme.current.playhead)
                                    .frame(width: 8, height: geo.size.height)
                                    .offset(x: (geo.size.width - 24) * progress + 20)
                                    .animation(.linear(duration: 0.05), value: vm.playbackPosition)
                            }
                        }
                    }
                    .frame(maxHeight: min(CGFloat(vm.layerCount) * 40 + 8, 280))
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }

            if let vm = viewModel, vm.isRecording {
                WaveformView(samples: vm.liveWaveformSamples, color: theme.current.waveform)
                    .frame(height: 56)
                    .padding(.horizontal)
                    .padding(.top, 10)
            }

            Spacer(minLength: 4)

            Text(formattedDuration)
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .padding(.bottom, 16)
                .accessibilityLabel("Duration: \(formattedDuration)")

            RecordButton(
                isRecording: viewModel?.isRecording ?? false,
                action: toggleRecording,
                recordColor: theme.current.record
            )
            .accessibilityLabel(viewModel?.isRecording == true ? "Stop recording" : "Start recording")

            Text(statusText)
                .font(.system(.caption2, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer(minLength: 4)

            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    Button {
                        viewModel?.loopingEnabled.toggle()
                    } label: {
                        Image(systemName: "repeat")
                            .font(.title3)
                            .foregroundStyle(viewModel?.loopingEnabled == true ? theme.current.accent : .secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                viewModel?.loopingEnabled == true
                                    ? AnyShapeStyle(theme.current.accent.opacity(0.15))
                                    : AnyShapeStyle(.ultraThinMaterial),
                                in: Circle()
                            )
                            .overlay(
                                Circle().strokeBorder(
                                    viewModel?.loopingEnabled == true
                                        ? theme.current.accent.opacity(0.4)
                                        : .primary.opacity(0.08),
                                    lineWidth: viewModel?.loopingEnabled == true ? 1.0 : 0.5
                                )
                            )
                    }
                    .animation(.easeOut(duration: 0.15), value: viewModel?.loopingEnabled)
                    .accessibilityLabel(viewModel?.loopingEnabled == true ? "Disable loop" : "Enable loop")

                    Button(action: { viewModel?.togglePlayback() }) {
                        Image(systemName: viewModel?.isPlaying == true ? "stop.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
                    }
                    .disabled(viewModel?.layerCount == 0 || viewModel?.isRecording == true)
                    .accessibilityLabel(viewModel?.isPlaying == true ? "Stop playback" : "Play all layers")

                    if !isRegularWidth {
                        Button(action: { showMixer = true }) {
                            Image(systemName: "slider.vertical.3")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
                        }
                        .disabled(viewModel?.layerCount == 0 || viewModel?.isRecording == true)
                        .accessibilityLabel("Open mixer")
                    }
                }

                if let layerCount = viewModel?.layerCount, layerCount > 0 {
                    HStack(spacing: 5) {
                        ForEach(0..<layerCount, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(theme.current.accent.opacity(i == layerCount - 1 ? 0.8 : 0.25))
                                .frame(width: 16, height: 3)
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
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 16) {
                Button { showLibrary = true } label: {
                    Image(systemName: "folder")
                }
                .accessibilityLabel("Project library")
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                Button { showExport = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel?.layerCount == 0 || viewModel?.isRecording == true)
                .accessibilityLabel("Export project")

                Button { viewModel?.newProject() } label: {
                    Image(systemName: "plus")
                }
                .disabled(viewModel?.isRecording == true)
                .accessibilityLabel("New project")
            }
        }
    }

    private func layerWaveformRow(layer: Layer, vm: RecorderViewModel) -> some View {
        let projectDuration = vm.effectiveDuration
        let fraction = projectDuration > 0 ? layer.duration / projectDuration : 1.0

        return HStack(spacing: 8) {
            Text("\(layer.sortOrder + 1)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            GeometryReader { geo in
                if let samples = vm.layerWaveforms[layer.id], !samples.isEmpty {
                    WaveformView(samples: samples, color: theme.current.waveform.opacity(0.6))
                        .frame(width: geo.size.width * fraction, height: geo.size.height)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: geo.size.width * fraction, height: geo.size.height)
                }
            }
            .frame(height: 36)
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
        let duration: TimeInterval
        if viewModel?.isPlaying == true, viewModel?.isRecording != true {
            duration = viewModel?.playbackPosition ?? 0
        } else {
            duration = viewModel?.recordingDuration ?? 0
        }
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
            } else if viewModel.layerCount > 0 && !hasShownBluetoothWarning && isBluetoothAudioConnected {
                showBluetoothWarning = true
            } else {
                viewModel.startRecording()
            }
        }
    }

    private var isBluetoothAudioConnected: Bool {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try? session.setActive(true)
        let outputs = session.currentRoute.outputs
        return outputs.contains { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE }
    }
}

#Preview {
    RecorderView()
        .modelContainer(for: [Project.self, Layer.self], inMemory: true)
        .environment(ThemeManager())
}
