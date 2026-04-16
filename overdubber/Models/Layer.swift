import Foundation
import SwiftData

@Model
final class Layer {
    var id: UUID
    var sortOrder: Int
    var fileName: String
    var volume: Float
    var isMuted: Bool
    var duration: TimeInterval
    var createdDate: Date

    var project: Project?

    init(sortOrder: Int, fileName: String, duration: TimeInterval) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.fileName = fileName
        self.volume = 1.0
        self.isMuted = false
        self.duration = duration
        self.createdDate = .now
    }
}
