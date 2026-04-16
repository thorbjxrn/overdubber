import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var createdDate: Date
    var lastModifiedDate: Date
    var duration: TimeInterval

    @Relationship(deleteRule: .cascade, inverse: \Layer.project)
    var layers: [Layer]

    init(name: String = "Untitled") {
        self.id = UUID()
        self.name = name
        self.createdDate = .now
        self.lastModifiedDate = .now
        self.duration = 0
        self.layers = []
    }
}
