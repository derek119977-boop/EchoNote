import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

actor SummaryService {
    func summarize(_ transcript: String, mode: NoteMode) async -> String {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "No speech was detected in this recording." }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                let instructions = mode == .sermon ? """
                You organize sermon notes faithfully. Never invent details. Use plain text with these sections when supported by the transcript: THEME, SCRIPTURE, KEY POINTS, MEMORABLE STATEMENTS, TAKEAWAYS, SUMMARY. Keep Scripture references exactly as spoken.
                """ : """
                You organize spoken notes faithfully. Never invent details. Use plain text with a concise SUMMARY, KEY POINTS, ACTION ITEMS, and IMPORTANT DETAILS. Omit sections unsupported by the transcript.
                """
                do { let session = LanguageModelSession(model: model, instructions: instructions); let response = try await session.respond(to: transcript); return response.content }
                catch { }
            }
        }
        #endif
        return "SUMMARY\n\(transcript)"
    }
}
