import AVFoundation

struct WaveformGenerator {
    static func samples(from url: URL, targetCount: Int = 200) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { return [] }

        let length = Int(file.length)
        guard length > 0, let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: file.processingFormat.sampleRate,
            channels: 1,
            interleaved: false
        ) else { return [] }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length)) else {
            return []
        }

        do {
            try file.read(into: buffer)
        } catch {
            return []
        }

        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let frameCount = Int(buffer.frameLength)

        let samplesPerBin = max(frameCount / targetCount, 1)
        var result = [Float]()
        result.reserveCapacity(targetCount)

        for bin in 0..<targetCount {
            let start = bin * samplesPerBin
            let end = min(start + samplesPerBin, frameCount)
            guard start < frameCount else { break }

            var peak: Float = 0
            for i in start..<end {
                let abs = Swift.abs(channelData[i])
                if abs > peak { peak = abs }
            }
            result.append(peak)
        }

        return result
    }

    static func downsample(buffer: AVAudioPCMBuffer, targetCount: Int = 100) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return [] }

        let samplesPerBin = max(frameCount / targetCount, 1)
        var result = [Float]()
        result.reserveCapacity(targetCount)

        for bin in 0..<targetCount {
            let start = bin * samplesPerBin
            let end = min(start + samplesPerBin, frameCount)
            guard start < frameCount else { break }

            var peak: Float = 0
            for i in start..<end {
                let abs = Swift.abs(channelData[i])
                if abs > peak { peak = abs }
            }
            result.append(peak)
        }

        return result
    }
}
