import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TodoItem> { $0.completedAt != nil },
           sort: [SortDescriptor(\TodoItem.completedAt, order: .reverse)])
    private var items: [TodoItem]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        Label("Created: \(item.createdAt.stamp)", systemImage: "plus.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let done = item.completedAt {
                            Label("Completed: \(done.stamp)", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .leading) {
                        Button("Restore", systemImage: "arrow.uturn.backward") {
                            withAnimation { item.completedAt = nil }
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(items[index]) }
                }
            }
            .navigationTitle("Archive")
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView("No completed items",
                                           systemImage: "archivebox",
                                           description: Text("Items you check off will appear here."))
                }
            }
        }
    }
}
