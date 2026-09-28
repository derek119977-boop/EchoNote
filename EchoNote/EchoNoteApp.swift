import SwiftUI
import SwiftData

@main
struct EchoNoteApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: EchoNote.self)
    }
}
