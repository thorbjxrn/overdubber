import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    var color: Color = .red

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let barWidth = size.width / CGFloat(max(samples.count, 1))

            for (index, sample) in samples.enumerated() {
                let amplitude = CGFloat(sample) * midY
                let x = CGFloat(index) * barWidth

                let rect = CGRect(
                    x: x,
                    y: midY - amplitude,
                    width: max(barWidth - 0.5, 0.5),
                    height: amplitude * 2
                )

                context.fill(Path(roundedRect: rect, cornerRadius: 0.5), with: .color(color))
            }
        }
    }
}

#Preview {
    let testSamples: [Float] = (0..<100).map { i in
        let t = Float(i) / 100
        return abs(sin(t * .pi * 4)) * Float.random(in: 0.3...1.0)
    }

    VStack(spacing: 20) {
        WaveformView(samples: testSamples, color: .red)
            .frame(height: 60)

        WaveformView(samples: testSamples, color: .orange.opacity(0.7))
            .frame(height: 40)
    }
    .padding()
    .background(Color.black)
}
