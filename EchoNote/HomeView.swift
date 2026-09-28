import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \EchoNote.createdAt, order: .reverse) private var notes: [EchoNote]
    @State private var recorder = AudioRecorder()
    @State private var mode: NoteMode = .general
    @State private var processing = false
    @State private var status = "Ready to capture"
    @State private var alert: String?
    let goToLibrary: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors:[Color(.systemBackground), Color.blue.opacity(0.08)], startPoint:.top, endPoint:.bottom).ignoresSafeArea()
                ScrollView { VStack(spacing: 22) {
                    brand
                    Picker("Mode", selection:$mode) { ForEach(NoteMode.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).padding(.horizontal)
                    recorderCard
                    recent
                }.padding(.bottom, 30) }
            }.navigationBarHidden(true)
        }.alert("EchoNote", isPresented: Binding(get:{ alert != nil }, set:{ if !$0 { alert=nil } })) { Button("OK"){} } message:{ Text(alert ?? "") }
    }

    private var brand: some View { VStack(spacing:5) { HStack(spacing:10){ Image(systemName:"waveform.circle.fill").font(.system(size:34)).foregroundStyle(.blue); Text("EchoNote").font(.system(size:32, weight:.bold, design:.rounded)) }.padding(.top,24); Text("Listen. Capture. Remember.").foregroundStyle(.secondary).font(.subheadline) } }

    private var recorderCard: some View {
        VStack(spacing:18) {
            ZStack { Circle().fill(Color.blue.opacity(0.09)).frame(width:178,height:178); Circle().stroke(Color.blue.opacity(0.18),lineWidth:1).frame(width:150,height:150)
                Button { Task { await recordTapped() } } label: { ZStack { Circle().fill(recorder.isRecording ? Color.red : Color.blue).frame(width:108,height:108).shadow(color:(recorder.isRecording ? Color.red:Color.blue).opacity(0.25),radius:18,y:8); Image(systemName:recorder.isRecording ? "stop.fill":"mic.fill").font(.system(size:38,weight:.semibold)).foregroundStyle(.white) } }.disabled(processing)
            }
            Text(recorder.isRecording ? time(recorder.elapsed) : processing ? "Working on your note…" : status).font(.headline)
            if recorder.isRecording { Text("Tap to finish recording").font(.caption).foregroundStyle(.secondary) }
            else { Text(mode == .sermon ? "Sermon mode organizes Scripture, key points and takeaways." : "Record a thought, meeting, reminder or idea.").multilineTextAlignment(.center).font(.subheadline).foregroundStyle(.secondary) }
            if processing { ProgressView().controlSize(.large) }
        }.frame(maxWidth:.infinity).padding(.vertical,26).padding(.horizontal,20).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:30,style:.continuous)).overlay(RoundedRectangle(cornerRadius:30).stroke(.white.opacity(0.18))).padding(.horizontal)
    }

    private var recent: some View { VStack(alignment:.leading,spacing:12){ HStack { Text("Recent Notes").font(.title3.bold()); Spacer(); Button("See All",action:goToLibrary) }.padding(.horizontal)
        if notes.isEmpty { ContentUnavailableView("No notes yet", systemImage:"waveform", description:Text("Your recordings and notes will appear here.")) }
        else { ForEach(notes.prefix(3)) { note in NavigationLink { NoteDetailView(note:note) } label:{ NoteRow(note:note) }.buttonStyle(.plain).padding(.horizontal) } }
    } }

    private func recordTapped() async {
        if recorder.isRecording { guard let result=recorder.stop() else{return}; await process(result); return }
        guard await recorder.requestPermission() else { alert=recorder.errorMessage; return }
        do { try recorder.start(); status="Recording" } catch { alert=error.localizedDescription }
    }
    private func process(_ result: RecordingResult) async {
        processing=true; status="Transcribing on device"
        do {
            let transcript=try await TranscriptionService().transcribe(result.url)
            status="Organizing your note"
            let summary=await SummaryService().summarize(transcript, mode:mode)
            let title=makeTitle(transcript, mode:mode)
            context.insert(EchoNote(title:title,mode:mode,transcript:transcript,summary:summary,duration:result.duration,audioFilename:result.url.lastPathComponent))
            try? context.save(); status="Saved"
        } catch {
            let title=mode == .sermon ? "Sermon Recording" : "Voice Recording"
            context.insert(EchoNote(title:title,mode:mode,transcript:"Transcription unavailable: \(error.localizedDescription)",summary:"Your audio recording was saved. You can play it back from this note.",duration:result.duration,audioFilename:result.url.lastPathComponent)); try? context.save(); alert="The audio was saved, but transcription could not finish. \(error.localizedDescription)"; status="Saved audio"
        }
        processing=false
    }
    private func makeTitle(_ text:String, mode:NoteMode)->String { let words=text.split(separator:" ").prefix(7).joined(separator:" "); return words.isEmpty ? (mode == .sermon ? "Sermon Note":"New Note") : words }
    private func time(_ s:Double)->String { String(format:"%02d:%02d",Int(s)/60,Int(s)%60) }
}
