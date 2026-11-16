import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("To Do", systemImage: "checklist") {
                TodoListView()
            }
            Tab("Archive", systemImage: "archivebox") {
                ArchiveView()
            }
        }
    }
}

extension Date {
    /// e.g. "16 Nov 2026, 14:32"
    var stamp: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
