import SwiftUI
import SwiftData

struct RootView: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            HomeView(goToLibrary: { tab = 1 }).tag(0).tabItem { Label("Home", systemImage: "house.fill") }
            LibraryView().tag(1).tabItem { Label("Notes", systemImage: "note.text") }
            SettingsView().tag(2).tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }.tint(.blue)
    }
}
