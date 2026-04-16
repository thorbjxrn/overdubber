import SwiftUI

struct ExportView: View {
    let projectName: String
    let layers: [(url: URL, volume: Float)]
    @Environment(\.dismiss) private var dismiss

    @State private var fileName: String
    @State private var format: ExportFormat = .m4a
    @State private var isExporting = false
    @State private var progress: Double = 0
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var exportTask: Task<Void, Never>?

    private let exporter = AudioExporter()

    init(projectName: String, layers: [(url: URL, volume: Float)]) {
        self.projectName = projectName
        self.layers = layers
        self._fileName = State(initialValue: projectName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("File Name") {
                    TextField("Name", text: $fileName)
                        .font(.system(.body, design: .monospaced))
                        .disabled(isExporting || exportedURL != nil)
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isExporting || exportedURL != nil)
                }

                if isExporting {
                    Section("Exporting") {
                        ProgressView(value: progress)
                            .tint(.red)
                        Text("\(Int(progress * 100))%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                if let exportedURL {
                    Section("Done") {
                        ShareLink(item: exportedURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            dismiss()
                        } label: {
                            Label("Close", systemImage: "checkmark.circle")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isExporting ? "Stop" : "Cancel") {
                        if isExporting {
                            exportTask?.cancel()
                            exportTask = nil
                            isExporting = false
                            errorMessage = "Export cancelled"
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export") { startExport() }
                        .bold()
                        .disabled(isExporting || fileName.isEmpty || exportedURL != nil)
                }
            }
        }
    }

    private func startExport() {
        let name = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isExporting = true
        errorMessage = nil
        progress = 0

        exportTask = Task {
            do {
                let url = try await exporter.export(
                    layers: layers,
                    format: format,
                    name: name
                ) { p in
                    Task { @MainActor in
                        progress = p
                    }
                }
                guard !Task.isCancelled else { return }
                exportedURL = url
            } catch is CancellationError {
                errorMessage = "Export cancelled"
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
            exportTask = nil
        }
    }
}
