import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var transcript: String
    var summary: String
    var createdAt: Date
    var duration: Double
    var audioFileName: String?

    init(
        title: String = "Voice Note",
        transcript: String = "",
        summary: String = "",
        createdAt: Date = .now,
        duration: Double = 0,
        audioFileName: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.transcript = transcript
        self.summary = summary
        self.createdAt = createdAt
        self.duration = duration
        self.audioFileName = audioFileName
    }
}
