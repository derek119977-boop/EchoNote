import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @AppStorage("appearance") private var appearance = "system"
    @State private var recorder = AudioRecorder()
    @State private var status = "Ready to listen?"

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 28) {
                    Spacer()
                    Text("EchoNote").font(.largeTitle.bold())
                    Text("Listen. Capture. Remember.").foregroundStyle(.secondary)

                    Button {
                        Task { await toggle() }
                    } label: {
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white)
                            .frame(width: 116, height: 116)
                            .background(recorder.isRecording ? Color.red : Color.blue)
                            .clipShape(Circle())
                    }

                    Text(recorder.isRecording ? format(recorder.elapsed) : status)
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                List {
                    ForEach(notes) { note in
                        VStack(alignment: .leading) {
                            Text(note.title).font(.headline)
                            Text(note.transcript).lineLimit(3).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(notes[index]) }
                    }
                }
                .navigationTitle("Notes")
            }
            .tabItem { Label("Notes", systemImage: "note.text") }

            NavigationStack {
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }
                    Section("Privacy") {
                        Text("Recordings and notes are stored locally on this device.")
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }

    private func toggle() async {
        if recorder.isRecording {
            guard let (url, duration) = recorder.stop() else { return }
            let note = Note(
                title: "Voice Note \(Date().formatted(date: .abbreviated, time: .shortened))",
                transcript: "Recording saved locally. On-device transcription is the next integration step.",
                duration: duration,
                audioFileName: url.lastPathComponent
            )
            modelContext.insert(note)
            try? modelContext.save()
            status = "Saved locally"
        } else {
            guard await recorder.requestPermission() else {
                status = "Microphone permission required"
                return
            }
            do {
                try recorder.start()
                status = "Listening…"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
