import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TodoItem> { $0.completedAt == nil },
           sort: \TodoItem.createdAt)
    private var items: [TodoItem]

    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add something to do…", text: $newTitle)
                            .focused($inputFocused)
                            .submitLabel(.done)
                            .onSubmit(add)
                        Button(action: add) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.borderless)
                        .disabled(trimmed.isEmpty)
                    }
                }

                Section {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Button {
                                complete(item)
                            } label: {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                Text(item.createdAt.stamp)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Done", systemImage: "checkmark") { complete(item) }
                                .tint(.green)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(items[index]) }
                    }
                }
            }
            .navigationTitle("To Do")
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView("Nothing to do",
                                           systemImage: "checkmark.circle",
                                           description: Text("Add an item above."))
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var trimmed: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func add() {
        guard !trimmed.isEmpty else { return }
        withAnimation {
            context.insert(TodoItem(title: trimmed))
        }
        newTitle = ""
        inputFocused = true
    }

    private func complete(_ item: TodoItem) {
        withAnimation {
            item.completedAt = .now
        }
    }
}
