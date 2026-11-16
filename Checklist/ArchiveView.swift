import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TodoItem> { $0.completedAt != nil },
           sort: [SortDescriptor(\TodoItem.completedAt, order: .reverse)])
    private var items: [TodoItem]

    /// Completed items grouped by the calendar day they were completed, newest day first.
    private var groups: [(day: Date, items: [TodoItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.completedAt ?? item.createdAt)
        }
        return grouped
            .map { (day: $0.key, items: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.day) { group in
                    Section {
                        ForEach(group.items) { item in
                            row(for: item)
                        }
                        .onDelete { offsets in
                            for index in offsets { context.delete(group.items[index]) }
                        }
                    } header: {
                        HStack {
                            Text(group.day.sectionTitle)
                            Spacer()
                            Text("\(group.items.count)")
                        }
                    }
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

    private func row(for item: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .strikethrough()
                .foregroundStyle(.secondary)
            Label("Created: \(item.createdAt.stamp)", systemImage: "plus.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let done = item.completedAt {
                Label("Completed: \(done.formatted(date: .omitted, time: .shortened))",
                      systemImage: "checkmark.circle")
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
}

private extension Date {
    /// "Today", "Yesterday", or a full date like "Monday, November 16, 2026".
    var sectionTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return String(localized: "Today") }
        if calendar.isDateInYesterday(self) { return String(localized: "Yesterday") }
        return formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }
}
