import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var notes:[EchoNote]
    @AppStorage("appearance") private var appearance="System"
    var body:some View { NavigationStack { Form {
        Section("EchoNote"){HStack{Image(systemName:"waveform.circle.fill").font(.largeTitle).foregroundStyle(.blue);VStack(alignment:.leading){Text("EchoNote").font(.headline);Text("Listen. Capture. Remember.").font(.caption).foregroundStyle(.secondary)}}}
        Section("Appearance"){Picker("Theme",selection:$appearance){Text("System").tag("System");Text("Light").tag("Light");Text("Dark").tag("Dark")}}
        Section("On-device features"){Label("Audio recordings stay in EchoNote's local storage",systemImage:"iphone");Label("Speech recognition prefers on-device processing when supported",systemImage:"waveform.badge.mic");Label("Apple Intelligence organizes notes when available",systemImage:"sparkles")}
        Section("Library"){LabeledContent("Saved notes",value:"\(notes.count)");LabeledContent("Saved audio",value:storageSize())}
        Section("About"){LabeledContent("Version",value:"2.0");Text("EchoNote works without your HavenServer. Availability of transcription and Apple Intelligence depends on the iPhone and installed language models.").font(.footnote).foregroundStyle(.secondary)}
    }.navigationTitle("Settings") }.preferredColorScheme(appearance == "Dark" ? .dark : appearance == "Light" ? .light : nil) }
    private func storageSize()->String { let urls=(try? FileManager.default.contentsOfDirectory(at:AudioRecorder.recordingsDirectory,includingPropertiesForKeys:[.fileSizeKey])) ?? []; let bytes=urls.reduce(0){$0+((try?$1.resourceValues(forKeys:[.fileSizeKey]).fileSize) ?? 0)}; return ByteCountFormatter.string(fromByteCount:Int64(bytes),countStyle:.file) }
}
