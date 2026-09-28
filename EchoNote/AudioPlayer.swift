import AVFoundation
import Observation

@MainActor @Observable
final class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    var isPlaying = false
    private var player: AVAudioPlayer?
    func toggle(url: URL) {
        if isPlaying { player?.stop(); isPlaying=false; return }
        do { player = try AVAudioPlayer(contentsOf: url); player?.delegate=self; player?.play(); isPlaying=true } catch { isPlaying=false }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { isPlaying=false }
}
