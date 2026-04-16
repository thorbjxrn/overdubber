import SwiftUI

struct LayerRowView: View {
    @Environment(ThemeManager.self) private var theme
    let layerNumber: Int
    let samples: [Float]
    @Binding var volume: Float
    @Binding var isMuted: Bool
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(layerNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            WaveformView(samples: samples, color: isMuted ? .gray : theme.current.waveform.opacity(0.7))
                .frame(height: 32)
                .opacity(isMuted ? 0.4 : 1.0)

            Slider(value: $volume, in: 0...1)
                .tint(theme.current.accent)
                .frame(width: 80)

            Button {
                isMuted.toggle()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(isMuted ? .secondary : .primary)
                    .frame(width: 28, height: 28)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption2)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
