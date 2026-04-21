import AVFoundation
import ZIPFoundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case m4a = "M4A"
    case wav = "WAV"
    case stems = "Stems"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .m4a: "m4a"
        case .wav: "wav"
        case .stems: "zip"
        }
    }
}

actor AudioExporter {
    enum ExportError: LocalizedError {
        case noLayers
        case exportFailed(String)

        var errorDescription: String? {
            switch self {
            case .noLayers: "No layers to export"
            case .exportFailed(let reason): "Export failed: \(reason)"
            }
        }
    }

    func export(
        layers: [(url: URL, volume: Float)],
        format: ExportFormat,
        name: String,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        guard !layers.isEmpty else { throw ExportError.noLayers }

        let outputURL = FileManager.exportsDirectory()
            .appendingPathComponent("\(name).\(format.fileExtension)")

        try? Foundation.FileManager.default.removeItem(at: outputURL)

        switch format {
        case .wav:
            try await exportWAV(layers: layers, to: outputURL, onProgress: onProgress)
        case .m4a:
            try await exportM4A(layers: layers, to: outputURL, onProgress: onProgress)
        case .stems:
            try await exportStems(layers: layers, to: outputURL, name: name, onProgress: onProgress)
        }

        return outputURL
    }

    // MARK: - WAV (offline AVAudioEngine rendering)

    private func exportWAV(
        layers: [(url: URL, volume: Float)],
        to outputURL: URL,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws {
        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode

        var files: [AVAudioFile] = []
        var players: [AVAudioPlayerNode] = []
        var maxLength: AVAudioFramePosition = 0

        for (url, volume) in layers {
            let file = try AVAudioFile(forReading: url)
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mainMixer, format: file.processingFormat)
            player.volume = volume
            files.append(file)
            players.append(player)
            maxLength = max(maxLength, file.length)
        }

        guard let renderFormat = files.first?.processingFormat else {
            throw ExportError.exportFailed("No audio format available")
        }

        try engine.enableManualRenderingMode(.offline, format: renderFormat, maximumFrameCount: 4096)
        try engine.start()

        for (i, player) in players.enumerated() {
            player.scheduleFile(files[i], at: nil, completionHandler: nil)
            player.play()
        }

        let totalFrames = AVAudioFrameCount(maxLength)
        var framesWritten: AVAudioFrameCount = 0

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: renderFormat.sampleRate,
                AVNumberOfChannelsKey: renderFormat.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
        )

        guard let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096) else {
            throw ExportError.exportFailed("Could not create buffer")
        }

        while framesWritten < totalFrames {
            let framesToRender = min(4096, totalFrames - framesWritten)
            let status = try engine.renderOffline(framesToRender, to: buffer)

            switch status {
            case .success:
                try outputFile.write(from: buffer)
                framesWritten += buffer.frameLength
                onProgress(Double(framesWritten) / Double(totalFrames))
            case .insufficientDataFromInputNode:
                framesWritten += framesToRender
                onProgress(Double(framesWritten) / Double(totalFrames))
            case .cannotDoInCurrentContext:
                try await Task.sleep(for: .milliseconds(10))
            case .error:
                throw ExportError.exportFailed("Render error")
            @unknown default:
                break
            }
        }

        engine.stop()
        for player in players { engine.detach(player) }
        onProgress(1.0)
    }

    // MARK: - M4A (AVAssetExportSession)

    private func exportM4A(
        layers: [(url: URL, volume: Float)],
        to outputURL: URL,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws {
        let composition = AVMutableComposition()
        var audioMixParams: [AVMutableAudioMixInputParameters] = []

        for (url, volume) in layers {
            let asset = AVURLAsset(url: url)
            guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }

            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { continue }

            let duration = try await asset.load(.duration)
            try compositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: assetTrack,
                at: .zero
            )

            let params = AVMutableAudioMixInputParameters(track: compositionTrack)
            params.setVolume(volume, at: .zero)
            audioMixParams.append(params)
        }

        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixParams

        guard let session = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw ExportError.exportFailed("Could not create export session")
        }

        session.outputURL = outputURL
        session.outputFileType = .m4a
        session.audioMix = audioMix

        onProgress(0.1)

        await session.export()

        if let error = session.error {
            throw ExportError.exportFailed(error.localizedDescription)
        }

        guard session.status == .completed else {
            throw ExportError.exportFailed("Export did not complete")
        }

        onProgress(1.0)
    }

    // MARK: - Stems (individual WAVs → ZIP)

    private func exportStems(
        layers: [(url: URL, volume: Float)],
        to outputURL: URL,
        name: String,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws {
        let tempDir = FileManager.stemsTempDirectory()
        let layerCount = layers.count
        let progressPerLayer = 0.9 / Double(layerCount)

        defer {
            try? Foundation.FileManager.default.removeItem(at: tempDir)
        }

        for (index, layer) in layers.enumerated() {
            let stemName = "\(name) - Track \(index + 1)"
            let stemURL = tempDir.appendingPathComponent("\(stemName).wav")

            try await exportWAV(
                layers: [(url: layer.url, volume: layer.volume)],
                to: stemURL,
                onProgress: { layerProgress in
                    let base = Double(index) * progressPerLayer
                    onProgress(base + layerProgress * progressPerLayer)
                }
            )
        }

        onProgress(0.9)

        try Foundation.FileManager.default.zipItem(at: tempDir, to: outputURL)

        onProgress(1.0)
    }
}
