import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func projectsDirectory() -> URL {
        let url = documentsDirectory.appendingPathComponent("Projects", isDirectory: true)
        ensureDirectoryExists(at: url)
        return url
    }

    static func projectDirectory(for projectId: UUID) -> URL {
        let url = projectsDirectory().appendingPathComponent(projectId.uuidString, isDirectory: true)
        ensureDirectoryExists(at: url)
        return url
    }

    static func layersDirectory(for projectId: UUID) -> URL {
        let url = projectDirectory(for: projectId).appendingPathComponent("layers", isDirectory: true)
        ensureDirectoryExists(at: url)
        return url
    }

    static func exportsDirectory() -> URL {
        let url = documentsDirectory.appendingPathComponent("Exports", isDirectory: true)
        ensureDirectoryExists(at: url)
        return url
    }

    static func layerFileURL(for projectId: UUID, layerIndex: Int) -> URL {
        layersDirectory(for: projectId).appendingPathComponent("layer-\(layerIndex).caf")
    }

    static func ensureDirectoryExists(at url: URL) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    static func deleteProjectFiles(for projectId: UUID) {
        let url = projectDirectory(for: projectId)
        try? FileManager.default.removeItem(at: url)
    }
}
