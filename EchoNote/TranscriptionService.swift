import Foundation
import Speech

actor TranscriptionService {
    enum Failure: LocalizedError { case denied, unavailable, failed(String); var errorDescription: String? { switch self { case .denied: "Speech Recognition permission is required to create transcripts."; case .unavailable: "On-device speech recognition is unavailable right now."; case .failed(let s): s } } }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) } }
    }

    func transcribe(_ url: URL) async throws -> String {
        guard await requestAuthorization() else { throw Failure.denied }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else { throw Failure.unavailable }
        let request = SFSpeechURLRecognitionRequest(url: url)
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        request.shouldReportPartialResults = false
        return try await withCheckedThrowingContinuation { continuation in
            var finished = false
            recognizer.recognitionTask(with: request) { result, error in
                if finished { return }
                if let error { finished=true; continuation.resume(throwing: Failure.failed(error.localizedDescription)); return }
                if let result, result.isFinal { finished=true; continuation.resume(returning: result.bestTranscription.formattedString) }
            }
        }
    }
}
