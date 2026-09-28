import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \EchoNote.createdAt, order: .reverse) private var notes:[EchoNote]
    @State private var search=""
    @State private var filter: Filter = .all
    enum Filter:String,CaseIterable,Identifiable { case all="All", general="General", sermon="Sermons", favorites="Favorites"; var id:String{rawValue} }
    var filtered:[EchoNote] { notes.filter { n in let kind = filter == .all || (filter == .general && n.mode == .general) || (filter == .sermon && n.mode == .sermon) || (filter == .favorites && n.isFavorite); let q=search.trimmingCharacters(in:.whitespacesAndNewlines); return kind && (q.isEmpty || n.title.localizedCaseInsensitiveContains(q) || n.transcript.localizedCaseInsensitiveContains(q) || n.summary.localizedCaseInsensitiveContains(q)) } }
    var body: some View { NavigationStack { VStack(spacing:10){ Picker("Filter",selection:$filter){ForEach(Filter.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented).padding(.horizontal)
        if filtered.isEmpty { Spacer(); ContentUnavailableView("No matching notes",systemImage:"note.text",description:Text("Record something on Home or change your search.")); Spacer() }
        else { List(filtered){ note in NavigationLink { NoteDetailView(note:note) } label:{ NoteRow(note:note) } }.listStyle(.plain) }
    }.navigationTitle("Notes").searchable(text:$search,prompt:"Search notes") } }
}

struct NoteRow: View { let note:EchoNote; var body:some View { HStack(spacing:13){ ZStack{RoundedRectangle(cornerRadius:12).fill((note.mode == .sermon ? Color.indigo:Color.blue).opacity(.12)).frame(width:44,height:44); Image(systemName:note.mode == .sermon ? "book.closed.fill":"waveform").foregroundStyle(note.mode == .sermon ? .indigo:.blue)}; VStack(alignment:.leading,spacing:4){Text(note.title).font(.headline).lineLimit(1); HStack{Text(note.mode.rawValue);Text("•");Text(note.createdAt,style:.date);Text("•");Text(duration(note.duration))}.font(.caption).foregroundStyle(.secondary)}; Spacer(); if note.isFavorite{Image(systemName:"star.fill").foregroundStyle(.yellow)} }.padding(.vertical,5) }
    private func duration(_ s:Double)->String {String(format:"%d:%02d",Int(s)/60,Int(s)%60)} }
