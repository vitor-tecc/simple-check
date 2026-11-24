import SwiftUI
import SwiftData
import WidgetKit

struct TodoListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: Self.openItems, sort: Self.listOrder)
    private var items: [TodoItem]

    // Spelled out with explicit types: inline in @Query they made the compiler time out.
    private static let openItems: Predicate<TodoItem> = #Predicate<TodoItem> { $0.completedAt == nil }
    private static let listOrder: [SortDescriptor<TodoItem>] = [
        SortDescriptor(\TodoItem.sortOrder),
        SortDescriptor(\TodoItem.createdAt),
    ]

    @State private var newTitle = ""
    @FocusState private var inputFocused: Bool
    @State private var editMode: EditMode = .inactive

    private var isEditing: Bool { editMode.isEditing }

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
                        TodoRow(item: item, isEditing: isEditing) { complete(item) }
                    }
                    .onMove(perform: move)
                    .onDelete { offsets in
                        for index in offsets { context.delete(items[index]) }
                    }
                }
            }
            .navigationTitle("To Do")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation { editMode = isEditing ? .inactive : .active }
                    }
                    .fontWeight(isEditing ? .semibold : .regular)
                    .disabled(items.isEmpty && !isEditing)
                }
            }
            .environment(\.editMode, $editMode)
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
            let next = (items.map(\.sortOrder).max() ?? 0) + 1
            context.insert(TodoItem(title: trimmed, sortOrder: next))
        }
        newTitle = ""
        inputFocused = true
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.sortOrder = Double(index)
        }
    }

    private func complete(_ item: TodoItem) {
        withAnimation {
            item.completedAt = .now
        }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let isEditing: Bool
    let onComplete: () -> Void

    @State private var draft = ""

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isEditing {
                Button(action: onComplete) {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("Task", text: $draft, axis: .vertical)
                        .onAppear { draft = item.title }
                        .onChange(of: draft) {
                            // Keep the last non-empty text if the field is cleared.
                            let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !text.isEmpty { item.title = text }
                        }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Text(item.title)
                    }
                }
                Text(item.createdAt.stamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .leading) {
            Button("Done", systemImage: "checkmark", action: onComplete)
                .tint(.green)
            Button(item.isPinned ? "Unpin" : "Pin",
                   systemImage: item.isPinned ? "pin.slash" : "pin") {
                withAnimation { item.isPinned.toggle() }
                WidgetCenter.shared.reloadAllTimelines()
            }
            .tint(.orange)
        }
    }
}
