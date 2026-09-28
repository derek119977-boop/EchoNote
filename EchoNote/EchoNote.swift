import Foundation
import SwiftData

@Model
final class EchoNote {
    var id: UUID
    var title: String
    var createdAt: Date
    var duration: Double
    var modeRaw: String
    var transcript: String
    var summary: String
    var audioFilename: String
    var isFavorite: Bool

    init(title: String, mode: NoteMode, transcript: String, summary: String, duration: Double, audioFilename: String) {
        self.id = UUID(); self.title = title; self.createdAt = .now; self.duration = duration
        self.modeRaw = mode.rawValue; self.transcript = transcript; self.summary = summary
        self.audioFilename = audioFilename; self.isFavorite = false
    }
    var mode: NoteMode { NoteMode(rawValue: modeRaw) ?? .general }
}

enum NoteMode: String, CaseIterable, Identifiable { case general = "General"; case sermon = "Sermon"; var id: String { rawValue } }
