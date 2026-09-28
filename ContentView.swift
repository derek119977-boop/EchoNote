import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    @AppStorage("appearance") private var appearance = "system"

    @State private var tab: Tab = .home
    @State private var recorder = AudioRecorder()
    @State private var status = "Tap the microphone to start."
    @State private var processing = false

    enum Tab {
        case home, notes, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                homeView
            }

            Tab("Notes", systemImage: "note.text", value: .notes) {
                notesView
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                settingsView
            }
        }
        .preferredColorScheme(colorScheme)
    }

    private var homeView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("AI NOTE TAKER")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("EchoNote")
                            .font(.largeTitle.bold())

                        Text("Listen. Capture. Remember.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 20) {
                        Button {
                            Task { await toggleRecording() }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        recorder.isRecording
                                        ? Color.red.gradient
                                        : Color.blue.gradient
                                    )
                                    .frame(width: 116, height: 116)

                                Image(
                                    systemName:
                                        recorder.isRecording
                                        ? "stop.fill"
                                        : "mic.fill"
                                )
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(processing)

                        Text(
                            recorder.isRecording
                            ? format(recorder.elapsed)
                            : processing
                                ? "Processing…"
                                : "Start Listening"
                        )
                        .font(.title2.bold())

                        Text(status)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34)
                    .padding(.horizontal)
                    .glassEffect(.regular, in: .rect(cornerRadius: 32))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent Notes")
                            .font(.title2.bold())

                        if notes.isEmpty {
                            ContentUnavailableView(
                                "No notes yet",
                                systemImage: "note.text",
                                description: Text(
                                    "Your recordings and notes will appear here."
                                )
                            )
                        } else {
                            ForEach(notes.prefix(3)) { note in
                                noteCard(note)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }

    private var notesView: some View {
        NavigationStack {
            List {
                ForEach(notes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title)
                                .font(.headline)

                            Text(
                                note.summary.isEmpty
                                ? note.transcript
                                : note.summary
                            )
                            .lineLimit(2)
                            .foregroundStyle(.secondary)

                            Text(note.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("Notes")
        }
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Storage") {
                    LabeledContent("Notes", value: "\(notes.count)")
                    Text(
                        "Recordings, transcripts, and notes are stored locally on this iPhone."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Label("No EchoNote server required", systemImage: "lock.shield")
                    Text(
                        "EchoNote can record, transcribe, organize, and save notes without connecting to your HavenServer."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func noteCard(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(note.title)
                .font(.headline)

            Text(note.summary.isEmpty ? note.transcript : note.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Text(note.createdAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func toggleRecording() async {
        if recorder.isRecording {
            guard let (url, duration) = recorder.stop() else { return }

            processing = true
            status = "Creating your transcript and notes…"

            do {
                let transcript = try await TranscriptionService()
                    .transcribe(fileURL: url)

                let summary = await SummaryService()
                    .summarize(transcript)

                let title = makeTitle(from: transcript)

                let note = Note(
                    title: title,
                    transcript: transcript,
                    summary: summary,
                    duration: duration,
                    audioFileName: url.lastPathComponent
                )

                modelContext.insert(note)
                try? modelContext.save()

                status = "Your note is ready."
            } catch {
                status = error.localizedDescription
            }

            processing = false
            return
        }

        let allowed = await recorder.requestPermission()

        guard allowed else {
            status = "Microphone permission is required."
            return
        }

        do {
            try recorder.start()
            status = "EchoNote is listening…"
        } catch {
            status = error.localizedDescription
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notes[index])
        }
    }

    private func makeTitle(from transcript: String) -> String {
        let words = transcript.split(separator: " ").prefix(6)
        let title = words.joined(separator: " ")
        return title.isEmpty ? "Voice Note" : title
    }

    private func format(_ time: TimeInterval) -> String {
        let total = Int(time)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

struct NoteDetailView: View {
    let note: Note

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !note.summary.isEmpty {
                    section("AI Notes", note.summary)
                }

                section("Original Transcript", note.transcript)

                LabeledContent(
                    "Recorded",
                    value: note.createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())

            Text(body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
