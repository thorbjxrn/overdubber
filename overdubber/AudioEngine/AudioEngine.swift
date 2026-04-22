import AVFoundation

final class AudioEngine {
    private let engine = AVAudioEngine()
    private let inputMixer = AVAudioMixerNode()
    private var audioFile: AVAudioFile?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var playbackFiles: [(url: URL, volume: Float)] = []
    var looping = false

    private(set) var isRecording = false
    private(set) var isPlaying = false
    var inputMonitoringEnabled = false {
        didSet { inputMixer.outputVolume = inputMonitoringEnabled ? 1.0 : 0.0 }
    }
    var tapeWarmthEnabled = false
    private var tapeSaturation = TapeSaturation()
    private let writeQueue = DispatchQueue(label: "com.overdubber.audiowrite", qos: .userInitiated)

    var onLiveWaveformSamples: (([Float]) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    var onRouteInterruption: (() -> Void)?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable, isRecording || isPlaying {
            onRouteInterruption?()
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began && (isRecording || isPlaying) {
            onRouteInterruption?()
        }
    }

    // MARK: - Recording (solo — no backing layers)

    func startRecording(to url: URL) throws {
        try configureSession()
        stopPlayback()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        audioFile = try AVAudioFile(forWriting: url, settings: recordingSettings(for: inputFormat))

        engine.disconnectNodeOutput(inputNode)
        engine.attach(inputMixer)
        engine.connect(inputNode, to: inputMixer, format: inputFormat)
        engine.connect(inputMixer, to: engine.mainMixerNode, format: inputFormat)
        inputMixer.outputVolume = inputMonitoringEnabled ? 1.0 : 0.0

        tapeSaturation.reset()
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

        engine.disconnectNodeOutput(inputNode)
        engine.attach(inputMixer)
        engine.connect(inputNode, to: inputMixer, format: inputFormat)
        engine.connect(inputMixer, to: mainMixer, format: inputFormat)
        inputMixer.outputVolume = inputMonitoringEnabled ? 1.0 : 0.0

        tapeSaturation.reset()
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
        engine.detach(inputMixer)

        for node in playerNodes {
            node.stop()
            engine.detach(node)
        }
        playerNodes.removeAll()

        engine.stop()
        writeQueue.sync {}
        let duration = audioFile?.duration ?? 0
        audioFile = nil
        isRecording = false
        isPlaying = false
        looping = false
        return duration
    }

    // MARK: - Playback

    func startPlayback(urls: [(url: URL, volume: Float)], loop: Bool = true) throws {
        try configureSession()
        stopPlayback()

        looping = loop
        playbackFiles = urls.filter { Foundation.FileManager.default.fileExists(atPath: $0.url.path) }
        guard !playbackFiles.isEmpty else { return }

        let mainMixer = engine.mainMixerNode
        engine.disconnectNodeOutput(engine.inputNode)

        try scheduleAllPlayers(on: mainMixer)

        engine.prepare()
        try engine.start()

        for node in playerNodes {
            node.play()
        }

        isPlaying = true
    }

    private func scheduleAllPlayers(on mixer: AVAudioMixerNode) throws {
        var longestIndex = 0
        var longestDuration: TimeInterval = 0

        for (i, (url, volume)) in playbackFiles.enumerated() {
            let file = try AVAudioFile(forReading: url)
            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            engine.connect(playerNode, to: mixer, format: file.processingFormat)
            playerNode.volume = volume
            playerNode.scheduleFile(file, at: nil)
            playerNodes.append(playerNode)

            if file.duration > longestDuration {
                longestDuration = file.duration
                longestIndex = i
            }
        }

        let longestNode = playerNodes[longestIndex]
        guard let sentinel = AVAudioPCMBuffer(pcmFormat: longestNode.outputFormat(forBus: 0), frameCapacity: 1) else { return }
        longestNode.scheduleBuffer(
            sentinel,
            at: nil,
            options: [],
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.isPlaying, !self.isRecording else { return }
                if self.looping {
                    self.restartLoop()
                } else {
                    self.onPlaybackFinished?()
                }
            }
        }
    }

    private func restartLoop() {
        guard isPlaying, looping else { return }

        for node in playerNodes {
            node.stop()
            engine.detach(node)
        }
        playerNodes.removeAll()

        let mixer = engine.mainMixerNode
        do {
            try scheduleAllPlayers(on: mixer)
            for node in playerNodes {
                node.play()
            }
            onPlaybackFinished?()
        } catch {
            onPlaybackFinished?()
        }
    }

    func stopPlayback() {
        looping = false

        for node in playerNodes {
            node.stop()
            engine.detach(node)
        }
        playerNodes.removeAll()
        playbackFiles.removeAll()

        if engine.isRunning && !isRecording {
            engine.stop()
        }

        isPlaying = false
    }

    func setVolume(at index: Int, volume: Float) {
        guard index < playerNodes.count else { return }
        playerNodes[index].volume = volume
        if index < playbackFiles.count {
            playbackFiles[index].volume = volume
        }
    }

    // MARK: - Helpers

    private func installRecordingTap(on inputNode: AVAudioInputNode, format: AVAudioFormat) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            if self.tapeWarmthEnabled {
                self.tapeSaturation.process(buffer)
            }
            self.writeQueue.async {
                try? self.audioFile?.write(from: buffer)
            }
            let samples = WaveformGenerator.downsample(buffer: buffer, targetCount: 50)
            self.onLiveWaveformSamples?(samples)
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
