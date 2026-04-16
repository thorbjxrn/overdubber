import SwiftUI

struct MixerView: View {
    @Bindable var viewModel: RecorderViewModel

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
                VStack(spacing: 0) {
                    ForEach(viewModel.sortedLayers) { layer in
                        LayerRowView(
                            layerNumber: layer.sortOrder + 1,
                            samples: viewModel.layerWaveforms[layer.id] ?? [],
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
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
