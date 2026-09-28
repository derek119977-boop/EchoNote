import Foundation
import AVFoundation
import Speech

@available(iOS 26.0, *)
actor TranscriptionService {

    enum TranscriptionError: LocalizedError {
        case unavailable
        case unsupportedLocale

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "On-device transcription is unavailable on this device."
            case .unsupportedLocale:
                return "The current language is not supported for transcription."
            }
        }
    }

    func transcribe(fileURL: URL) async throws -> String {
        guard SpeechTranscriber.isAvailable else {
            throw TranscriptionError.unavailable
        }

        guard let locale = await SpeechTranscriber.supportedLocale(
            equivalentTo: Locale.current
        ) else {
            throw TranscriptionError.unsupportedLocale
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            preset: .transcription
        )

        if let request = try await AssetInventory.assetInstallationRequest(
            supporting: [transcriber]
        ) {
            try await request.downloadAndInstall()
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: fileURL)

        var transcript = ""

        let resultsTask = Task {
            for try await result in transcriber.results {
                transcript += String(result.text.characters)
            }
        }

        let lastTime = try await analyzer.analyzeSequence(from: audioFile)

        if let lastTime {
            try await analyzer.finalizeAndFinish(through: lastTime)
        } else {
            analyzer.cancelAndFinishNow()
        }

        _ = try await resultsTask.value

        return transcript.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}
