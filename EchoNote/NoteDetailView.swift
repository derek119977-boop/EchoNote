import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var note: EchoNote
    @State private var player=AudioPlayer()
    @State private var confirmDelete=false
    var body:some View { ScrollView { VStack(alignment:.leading,spacing:18){
        VStack(alignment:.leading,spacing:8){ TextField("Title",text:$note.title).font(.title2.bold()); HStack{Label(note.mode.rawValue,systemImage:note.mode == .sermon ? "book.closed":"waveform"); Spacer(); Text(note.createdAt.formatted(date:.abbreviated,time:.shortened))}.font(.caption).foregroundStyle(.secondary) }.padding().glassCard()
        Button { player.toggle(url:AudioRecorder.url(for:note.audioFilename)) } label:{ HStack{Image(systemName:player.isPlaying ? "pause.circle.fill":"play.circle.fill").font(.title2); VStack(alignment:.leading){Text(player.isPlaying ? "Pause Recording":"Play Recording").bold();Text(duration(note.duration)).font(.caption).opacity(.75)};Spacer()} }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius:16))
        section("Organized Notes",note.summary,"sparkles")
        section("Original Transcript",note.transcript,"text.quote")
    }.padding() }.navigationTitle("Note").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItemGroup(placement:.topBarTrailing){ Button { note.isFavorite.toggle();try? context.save() } label:{Image(systemName:note.isFavorite ? "star.fill":"star")}; ShareLink(item:"\(note.title)\n\n\(note.summary)\n\nTranscript\n\(note.transcript)"){Image(systemName:"square.and.arrow.up")}; Button(role:.destructive){confirmDelete=true}label:{Image(systemName:"trash")} } }.confirmationDialog("Delete this note?",isPresented:$confirmDelete,titleVisibility:.visible){Button("Delete Note",role:.destructive){try? FileManager.default.removeItem(at:AudioRecorder.url(for:note.audioFilename));context.delete(note);try? context.save();dismiss()}} }
    private func section(_ title:String,_ body:String,_ icon:String)->some View { VStack(alignment:.leading,spacing:10){Label(title,systemImage:icon).font(.headline);Text(body).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading)}.padding().glassCard() }
    private func duration(_ s:Double)->String {String(format:"%d:%02d",Int(s)/60,Int(s)%60)}
}

extension View { func glassCard()->some View { self.background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:20,style:.continuous)).overlay(RoundedRectangle(cornerRadius:20).stroke(.primary.opacity(.06))) } }
