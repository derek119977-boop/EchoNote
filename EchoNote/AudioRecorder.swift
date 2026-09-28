import AVFoundation
import Foundation
import Observation

@MainActor @Observable
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var elapsed: TimeInterval = 0
    var errorMessage: String?
    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func requestPermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        if !granted { errorMessage = "Microphone access is off. Open Settings → Privacy & Security → Microphone and enable EchoNote." }
        return granted
    }

    func start() throws {
        errorMessage = nil
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let dir = Self.recordingsDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        let settings: [String: Any] = [AVFormatIDKey:Int(kAudioFormatMPEG4AAC), AVSampleRateKey:44100.0, AVNumberOfChannelsKey:1, AVEncoderBitRateKey:128000, AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue]
        let r = try AVAudioRecorder(url: url, settings: settings); r.delegate = self; r.isMeteringEnabled = true
        guard r.prepareToRecord(), r.record() else { throw RecorderError.startFailed }
        recorder = r; elapsed = 0; isRecording = true
        timer?.invalidate(); timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in Task { @MainActor in self?.elapsed = self?.recorder?.currentTime ?? 0 } }
    }

    func stop() -> RecordingResult? {
        guard let r = recorder else { return nil }
        let result = RecordingResult(url: r.url, duration: r.currentTime)
        r.stop(); recorder=nil; timer?.invalidate(); timer=nil; isRecording=false; elapsed=result.duration
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return result
    }

    static var recordingsDirectory: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Recordings", isDirectory: true) }
    static func url(for filename: String) -> URL { recordingsDirectory.appendingPathComponent(filename) }
}
struct RecordingResult { let url: URL; let duration: Double }
enum RecorderError: LocalizedError { case startFailed; var errorDescription: String? { "EchoNote could not start the microphone." } }
