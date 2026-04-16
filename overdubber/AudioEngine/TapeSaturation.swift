import AVFoundation
import Accelerate

struct TapeSaturation {
    var drive: Float = 0.4
    var warmth: Float = 0.3
    var compression: Float = 0.3

    private var prevSamples: [Float] = []

    mutating func process(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        if prevSamples.count != channelCount {
            prevSamples = [Float](repeating: 0, count: channelCount)
        }

        for ch in 0..<channelCount {
            let data = channelData[ch]

            for i in 0..<frameCount {
                var sample = data[i]

                let gain = 1.0 + drive * 3.0
                sample *= gain

                sample = tanh(sample)

                let ratio: Float = 1.0 + compression * 3.0
                let threshold: Float = 0.5
                let abs = Swift.abs(sample)
                if abs > threshold {
                    let excess = abs - threshold
                    let compressed = threshold + excess / ratio
                    sample = sample > 0 ? compressed : -compressed
                }

                let alpha = warmth * 0.4
                sample = sample * (1.0 - alpha) + prevSamples[ch] * alpha
                prevSamples[ch] = sample

                let makeup: Float = 1.0 / (1.0 + drive * 0.5)
                sample *= makeup

                data[i] = sample
            }
        }
    }
}
