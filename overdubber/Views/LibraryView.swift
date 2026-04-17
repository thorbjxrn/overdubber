import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Project.lastModifiedDate, order: .reverse) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var currentProjectId: UUID?
    var onSelectProject: (Project) -> Void
    var onDeleteActiveProject: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "waveform",
                        description: Text("Tap record to create your first project")
                    )
                } else {
                    List {
                        ForEach(projects) { project in
                            Button {
                                onSelectProject(project)
                                dismiss()
                            } label: {
                                projectRow(project)
                            }
                        }
                        .onDelete(perform: deleteProjects)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func projectRow(_ project: Project) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text("\(project.layers.count) layer\(project.layers.count == 1 ? "" : "s")")
                    Text("•")
                    Text(formattedDuration(project.duration))
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(project.lastModifiedDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func deleteProjects(at offsets: IndexSet) {
        var deletedActive = false
        for index in offsets {
            let project = projects[index]
            if project.id == currentProjectId {
                deletedActive = true
            }
            FileManager.deleteProjectFiles(for: project.id)
            modelContext.delete(project)
        }
        try? modelContext.save()
        if deletedActive {
            onDeleteActiveProject?()
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
