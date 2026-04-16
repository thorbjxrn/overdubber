import SwiftUI

struct MixerView: View {
    @Bindable var viewModel: RecorderViewModel
    @Environment(ThemeManager.self) private var theme

    private var projectDuration: TimeInterval {
        viewModel.currentProject?.duration ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MIXER")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.layerCount) layer\(viewModel.layerCount == 1 ? "" : "s")")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.sortedLayers) { layer in
                            LayerRowView(
                                layerNumber: layer.sortOrder + 1,
                                samples: viewModel.layerWaveforms[layer.id] ?? [],
                                durationFraction: projectDuration > 0 ? layer.duration / projectDuration : 1.0,
                                volume: Binding(
                                    get: { layer.volume },
                                    set: { viewModel.setLayerVolume(layer: layer, volume: $0) }
                                ),
                                isMuted: Binding(
                                    get: { layer.isMuted },
                                    set: { _ in viewModel.toggleLayerMute(layer: layer) }
                                ),
                                onDelete: { viewModel.deleteLayer(layer) }
                            )

                            if layer.id != viewModel.sortedLayers.last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }

                    if viewModel.isPlaying, projectDuration > 0 {
                        playheadOverlay
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var playheadOverlay: some View {
        GeometryReader { geo in
            let waveformLeading: CGFloat = 44
            let waveformTrailing: CGFloat = 160
            let waveformWidth = geo.size.width - waveformLeading - waveformTrailing
            let progress = viewModel.playbackPosition / projectDuration
            let x = waveformLeading + waveformWidth * progress

            PlayheadIndicator(color: theme.current.playhead)
                .frame(width: 8, height: geo.size.height)
                .offset(x: x - 4)
                .animation(.linear(duration: 0.05), value: viewModel.playbackPosition)
        }
    }
}

struct PlayheadIndicator: View {
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(color.opacity(0.8))
                .frame(width: 7, height: 5)

            Rectangle()
                .fill(color.opacity(0.5))
                .frame(width: 1)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
