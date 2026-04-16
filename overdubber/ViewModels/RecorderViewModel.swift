import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class RecorderViewModel {
    private let modelContext: ModelContext
    private let audioEngine = AudioEngine()

    var currentProject: Project?
    var isRecording = false
    var isPlaying = false
    var recordingDuration: TimeInterval = 0
    var playbackPosition: TimeInterval = 0
    var errorMessage: String?

    var liveWaveformSamples: [Float] = []
    var layerWaveforms: [UUID: [Float]] = [:]

    private var recordingStartTime: Date?
    private var durationTimer: Timer?

    var layerCount: Int {
        currentProject?.layers.count ?? 0
    }

    var sortedLayers: [Layer] {
        (currentProject?.layers ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        audioEngine.onLiveWaveformSamples = { [weak self] samples in
            Task { @MainActor [weak self] in
                self?.liveWaveformSamples = samples
            }
        }

        audioEngine.onPlaybackFinished = { [weak self] in
            Task { @MainActor [weak self] in
                self?.stopPlayback()
            }
        }
    }

    // MARK: - Project

    func newProject() {
        if isRecording { stopRecording() }
        if isPlaying { stopPlayback() }
        deleteCurrentProjectIfEmpty()

        let project = Project()
        modelContext.insert(project)
        save()
        currentProject = project
        layerWaveforms.removeAll()
        recordingDuration = 0
    }

    func loadProject(_ project: Project) {
        if isRecording { stopRecording() }
        if isPlaying { stopPlayback() }
        deleteCurrentProjectIfEmpty()

        currentProject = project
        recordingDuration = 0
        layerWaveforms.removeAll()
        loadAllWaveforms()
    }

    private func deleteCurrentProjectIfEmpty() {
        guard let project = currentProject, project.layers.isEmpty else { return }
        let projectDir = FileManager.projectDirectory(for: project.id)
        try? Foundation.FileManager.default.removeItem(at: projectDir)
        modelContext.delete(project)
        save()
    }

    // MARK: - Recording

    func startRecording() {
        if currentProject == nil {
            newProject()
        }
        guard let project = currentProject else { return }

        if isPlaying { stopPlayback() }

        let layerIndex = project.layers.count
        let fileURL = FileManager.layerFileURL(for: project.id, layerIndex: layerIndex)

        do {
            liveWaveformSamples = []
            if layerIndex == 0 {
                try audioEngine.startRecording(to: fileURL)
            } else {
                let existingLayers = layerData(for: project)
                try audioEngine.startOverdubRecording(to: fileURL, existingLayers: existingLayers)
            }
            isRecording = true
            isPlaying = layerIndex > 0
            recordingDuration = 0
            startDurationTimer()
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        let duration = audioEngine.stopRecording()
        isRecording = false
        isPlaying = false
        stopDurationTimer()

        guard let project = currentProject else { return }

        let layerIndex = project.layers.count
        let fileName = "layer-\(layerIndex).caf"

        let layer = Layer(sortOrder: layerIndex, fileName: fileName, duration: duration)
        layer.project = project
        modelContext.insert(layer)

        if duration > project.duration {
            project.duration = duration
        }
        project.lastModifiedDate = .now

        save()
        loadWaveform(for: layer, projectId: project.id)
        liveWaveformSamples = []
    }

    // MARK: - Waveforms

    func loadAllWaveforms() {
        guard let project = currentProject else { return }
        for layer in sortedLayers {
            loadWaveform(for: layer, projectId: project.id)
        }
    }

    private func loadWaveform(for layer: Layer, projectId: UUID) {
        let url = FileManager.layersDirectory(for: projectId)
            .appendingPathComponent(layer.fileName)
        let layerId = layer.id

        Task.detached(priority: .userInitiated) {
            let samples = WaveformGenerator.samples(from: url, targetCount: 200)
            await MainActor.run { [weak self] in
                self?.layerWaveforms[layerId] = samples
            }
        }
    }

    // MARK: - Layer Controls

    func setLayerVolume(layer: Layer, volume: Float) {
        layer.volume = volume
        if isPlaying, let index = sortedLayers.firstIndex(where: { $0.id == layer.id }) {
            audioEngine.setVolume(at: index, volume: layer.isMuted ? 0 : volume)
        }
        save()
    }

    func toggleLayerMute(layer: Layer) {
        layer.isMuted.toggle()
        if isPlaying, let index = sortedLayers.firstIndex(where: { $0.id == layer.id }) {
            audioEngine.setVolume(at: index, volume: layer.isMuted ? 0 : layer.volume)
        }
        save()
    }

    func deleteLayer(_ layer: Layer) {
        guard let project = currentProject else { return }

        let url = FileManager.layersDirectory(for: project.id)
            .appendingPathComponent(layer.fileName)
        try? Foundation.FileManager.default.removeItem(at: url)

        layerWaveforms.removeValue(forKey: layer.id)
        modelContext.delete(layer)

        let remaining = sortedLayers
        for (i, l) in remaining.enumerated() {
            l.sortOrder = i
        }

        if project.layers.isEmpty {
            project.duration = 0
        } else {
            project.duration = project.layers.map(\.duration).max() ?? 0
        }
        project.lastModifiedDate = .now
        save()
    }

    // MARK: - Playback

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard let project = currentProject, !project.layers.isEmpty else { return }

        let layers = layerData(for: project)
        guard !layers.isEmpty else { return }

        do {
            try audioEngine.startPlayback(urls: layers)
            isPlaying = true
            playbackPosition = 0
            startDurationTimer()
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        audioEngine.stopPlayback()
        isPlaying = false
        stopDurationTimer()
        playbackPosition = 0
    }

    // MARK: - Export

    var exportLayerData: [(url: URL, volume: Float)] {
        guard let project = currentProject else { return [] }
        return layerData(for: project)
    }

    // MARK: - Helpers

    private func layerData(for project: Project) -> [(url: URL, volume: Float)] {
        sortedLayers
            .filter { !$0.isMuted }
            .map { layer in
                let url = FileManager.layersDirectory(for: project.id)
                    .appendingPathComponent(layer.fileName)
                return (url: url, volume: layer.volume)
            }
    }

    // MARK: - Timer

    private func startDurationTimer() {
        recordingStartTime = Date()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.recordingStartTime else { return }
                let elapsed = Date().timeIntervalSince(start)
                if self.isRecording {
                    self.recordingDuration = elapsed
                }
                if self.isPlaying {
                    self.playbackPosition = elapsed
                }
            }
        }
    }

    private func stopDurationTimer() {
        if let start = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(start)
        }
        durationTimer?.invalidate()
        durationTimer = nil
        recordingStartTime = nil
    }

    // MARK: - Persistence

    private func save() {
        try? modelContext.save()
    }
}
