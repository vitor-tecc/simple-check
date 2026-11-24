import SwiftUI
import SwiftData
import WidgetKit

@main
struct ChecklistApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let container: ModelContainer = {
        do {
            return try SharedStore.makeContainer()
        } catch {
            fatalError("Could not open the task database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            // Refresh the widget with any changes made in the app.
            if phase != .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
