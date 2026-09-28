import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var startedAt: Date?

    var isRecording = false
    var elapsed: TimeInterval = 0

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func start() throws {
        let recordings = try recordingsDirectory()
        let url = recordings.appendingPathComponent("\(UUID().uuidString).m4a")

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .spokenAudio)
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.prepareToRecord()
        newRecorder.record()

        recorder = newRecorder
        startedAt = .now
        elapsed = 0
        isRecording = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(startedAt)
            }
        }
    }

    func stop() -> (URL, TimeInterval)? {
        guard let recorder else { return nil }

        let url = recorder.url
        let duration = elapsed

        recorder.stop()
        self.recorder = nil
        timer?.invalidate()
        timer = nil
        startedAt = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )

        return (url, duration)
    }

    private func recordingsDirectory() throws -> URL {
        let base = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let directory = base.appendingPathComponent(
            "Recordings",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }
}
