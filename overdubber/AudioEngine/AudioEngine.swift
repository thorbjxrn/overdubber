import AVFoundation

final class AudioEngine {
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var playerNodes: [AVAudioPlayerNode] = []

    private(set) var isRecording = false
    private(set) var isPlaying = false

    var onLiveWaveformSamples: (([Float]) -> Void)?

    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
    }

    // MARK: - Recording (solo — no backing layers)

    func startRecording(to url: URL) throws {
        try configureSession()
        stopPlayback()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        audioFile = try AVAudioFile(forWriting: url, settings: recordingSettings(for: inputFormat))

        installRecordingTap(on: inputNode, format: inputFormat)

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    // MARK: - Overdub Recording (record + play existing layers)

    func startOverdubRecording(
        to url: URL,
        existingLayers: [(url: URL, volume: Float)]
    ) throws {
        try configureSession()
        stopPlayback()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let mainMixer = engine.mainMixerNode

        audioFile = try AVAudioFile(forWriting: url, settings: recordingSettings(for: inputFormat))

        installRecordingTap(on: inputNode, format: inputFormat)

        for (layerURL, volume) in existingLayers {
            let file = try AVAudioFile(forReading: layerURL)
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            engine.connect(playerNode, to: mainMixer, format: file.processingFormat)
            playerNode.volume = volume
            playerNode.scheduleFile(file, at: nil)
            playerNodes.append(playerNode)
        }

        engine.prepare()
        try engine.start()

        for node in playerNodes {
            node.play()
        }

        isRecording = true
        isPlaying = true
    }

    func stopRecording() -> TimeInterval {
        engine.inputNode.removeTap(onBus: 0)

        for node in playerNodes {
            node.stop()
            engine.detach(node)
        }
        playerNodes.removeAll()

        engine.stop()
        let duration = audioFile?.duration ?? 0
        audioFile = nil
        isRecording = false
        isPlaying = false
        return duration
    }

    // MARK: - Playback

    func startPlayback(urls: [(url: URL, volume: Float)]) throws {
        try configureSession()
        stopPlayback()

        let mainMixer = engine.mainMixerNode

        for (url, volume) in urls {
            let file = try AVAudioFile(forReading: url)
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            engine.connect(playerNode, to: mainMixer, format: file.processingFormat)
            playerNode.volume = volume
            playerNode.scheduleFile(file, at: nil)
            playerNodes.append(playerNode)
        }

        engine.prepare()
        try engine.start()

        for node in playerNodes {
            node.play()
        }

        isPlaying = true
    }

    func stopPlayback() {
        for node in playerNodes {
            node.stop()
            engine.detach(node)
        }
        playerNodes.removeAll()

        if engine.isRunning {
            engine.stop()
        }

        isPlaying = false
    }

    func setVolume(at index: Int, volume: Float) {
        guard index < playerNodes.count else { return }
        playerNodes[index].volume = volume
    }

    // MARK: - Helpers

    private func installRecordingTap(on inputNode: AVAudioInputNode, format: AVAudioFormat) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            try? self?.audioFile?.write(from: buffer)
            let samples = WaveformGenerator.downsample(buffer: buffer, targetCount: 50)
            self?.onLiveWaveformSamples?(samples)
        }
    }

    private func recordingSettings(for format: AVAudioFormat) -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
    }
}

private extension AVAudioFile {
    var duration: TimeInterval {
        Double(length) / processingFormat.sampleRate
    }
}
