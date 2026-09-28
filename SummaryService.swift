import Foundation
import FoundationModels

@available(iOS 26.0, *)
actor SummaryService {

    func summarize(_ transcript: String) async -> String {
        guard !transcript.isEmpty else { return "" }

        let model = SystemLanguageModel.default

        guard model.isAvailable else {
            return transcript
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are EchoNote's note-taking engine.
            Preserve the speaker's meaning.
            Never invent information.
            Produce concise, useful notes with a short heading and bullet points.
            Keep names, dates, tasks, decisions, scripture references, and important details.
            """
        )

        do {
            let response = try await session.respond(
                to: """
                Turn this transcript into organized notes:

                \(transcript)
                """
            )
            return response.content
        } catch {
            return transcript
        }
    }
}
