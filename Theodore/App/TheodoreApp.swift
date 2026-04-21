import SwiftUI
import SwiftData

@main
struct TheodoreApp: App {

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Book.self, Chapter.self, Entry.self, ConversationMessage.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
