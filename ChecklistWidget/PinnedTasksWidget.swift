import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Data

struct PinnedTask: Identifiable {
    let id: String
    let title: String
}

struct PinnedEntry: TimelineEntry {
    let date: Date
    let tasks: [PinnedTask]
    /// False when the widget can't open the app's tasks (no shared App Group in this install).
    let storeAvailable: Bool

    static let sample = PinnedEntry(
        date: .now,
        tasks: [PinnedTask(id: "1", title: "Buy milk"),
                PinnedTask(id: "2", title: "Call the dentist"),
                PinnedTask(id: "3", title: "Pay rent")],
        storeAvailable: true)
}

enum PinnedLoader {
    private static let pinnedOpen: Predicate<TodoItem> =
        #Predicate<TodoItem> { $0.isPinned == true && $0.completedAt == nil }
    private static let listOrder: [SortDescriptor<TodoItem>] = [
        SortDescriptor(\TodoItem.sortOrder),
        SortDescriptor(\TodoItem.createdAt),
    ]

    static func load() -> PinnedEntry {
        guard SharedStore.groupContainerURL != nil,
              let container = try? SharedStore.makeContainer()
        else { return PinnedEntry(date: .now, tasks: [], storeAvailable: false) }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>(predicate: pinnedOpen, sortBy: listOrder)
        let items = (try? context.fetch(descriptor)) ?? []
        let tasks = items.map { PinnedTask(id: TaskID.encode($0.persistentModelID), title: $0.title) }
        return PinnedEntry(date: .now, tasks: tasks, storeAvailable: true)
    }
}

/// Turns a task's database ID into a string the widget button can carry, and back.
enum TaskID {
    static func encode(_ id: PersistentIdentifier) -> String {
        (try? JSONEncoder().encode(id))?.base64EncodedString() ?? ""
    }

    static func decode(_ string: String) -> PersistentIdentifier? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }
}

// MARK: - Checking a task off from the widget

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Check off task"

    @Parameter(title: "Task")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        guard let id = TaskID.decode(taskID) else { return .result() }
        let context = ModelContext(try SharedStore.makeContainer())
        var descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate<TodoItem> { $0.persistentModelID == id })
        descriptor.fetchLimit = 1
        if let item = try context.fetch(descriptor).first {
            item.completedAt = .now
            try context.save()
        }
        return .result()
    }
}

// MARK: - Timeline

struct PinnedProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinnedEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (PinnedEntry) -> Void) {
        completion(context.isPreview ? .sample : PinnedLoader.load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinnedEntry>) -> Void) {
        // The app asks for a refresh whenever tasks change, so no scheduled updates are needed.
        completion(Timeline(entries: [PinnedLoader.load()], policy: .never))
    }
}

// MARK: - Views

struct PinnedWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PinnedEntry

    var body: some View {
        Group {
            if family == .accessoryRectangular {
                lockScreen
            } else {
                homeScreen
            }
        }
        .containerBackground(.background, for: .widget)
    }

    private var maxRows: Int {
        switch family {
        case .systemLarge: return 9
        case .accessoryRectangular: return 3
        default: return 4
        }
    }

    private var hiddenCount: Int {
        max(0, entry.tasks.count - maxRows)
    }

    private var homeScreen: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Pinned", systemImage: "pin.fill")
                .font(.caption.bold())
                .foregroundStyle(.orange)

            if !entry.storeAvailable {
                Text("This install can't share tasks with the widget.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if entry.tasks.isEmpty {
                Text("No pinned tasks. In the app, swipe right on a task and tap Pin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.tasks.prefix(maxRows)) { task in
                    Button(intent: CompleteTaskIntent(taskID: task.id)) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                            Text(task.title)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
                if hiddenCount > 0 {
                    Text("+\(hiddenCount) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var lockScreen: some View {
        VStack(alignment: .leading, spacing: 1) {
            if !entry.storeAvailable {
                Text("Tasks unavailable")
            } else if entry.tasks.isEmpty {
                Label("No pinned tasks", systemImage: "pin")
            } else {
                ForEach(entry.tasks.prefix(maxRows)) { task in
                    Text("• \(task.title)")
                        .lineLimit(1)
                }
                if hiddenCount > 0 {
                    Text("+\(hiddenCount) more")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

@main
struct PinnedTasksWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PinnedTasks", provider: PinnedProvider()) { entry in
            PinnedWidgetView(entry: entry)
        }
        .configurationDisplayName("Pinned tasks")
        .description("Shows the tasks you pinned in Checklist. Tap one to check it off.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}
