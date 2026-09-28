import SwiftUI
import SwiftData

@main
struct EchoNoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Note.self)
    }
}
