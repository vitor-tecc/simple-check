import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var createdAt: Date
    var completedAt: Date?
    /// Position in the To Do list (lower comes first). Defaults to 0 for items saved before reordering existed.
    var sortOrder: Double = 0
    /// Pinned tasks are shown in the widget.
    var isPinned: Bool = false

    init(title: String, createdAt: Date = .now, sortOrder: Double = 0) {
        self.title = title
        self.createdAt = createdAt
        self.completedAt = nil
        self.sortOrder = sortOrder
    }
}
