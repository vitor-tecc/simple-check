import SwiftUI
import SwiftData

@main
struct ChecklistApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TodoItem.self)
    }
}
