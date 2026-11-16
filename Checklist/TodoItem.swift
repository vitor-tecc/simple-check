import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var createdAt: Date
    var completedAt: Date?

    init(title: String, createdAt: Date = .now) {
        self.title = title
        self.createdAt = createdAt
        self.completedAt = nil
    }
}
