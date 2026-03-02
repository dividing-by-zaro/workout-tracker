import AVFoundation
import Foundation

@Observable
final class BackgroundAudioService {
    private var audioPlayer: AVAudioPlayer?
    private var alertPlayer: AVAudioPlayer?
    private(set) var isPlaying = false

    func startSilentAudio() {
        guard !isPlaying else { return }
        guard let url = Bundle.main.url(forResource: "silence", withExtension: "caf") else {
            print("BackgroundAudioService: silence.caf not found in bundle")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.01
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            isPlaying = true
        } catch {
            print("BackgroundAudioService: failed to start — \(error)")
        }
    }

    func playAlertSound() {
        guard let url = Bundle.main.url(forResource: "alert_tone", withExtension: "caf") else {
            print("BackgroundAudioService: alert_tone.caf not found in bundle")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            alertPlayer = player
        } catch {
            print("BackgroundAudioService: failed to play alert — \(error)")
        }
    }

    func stopSilentAudio() {
        guard isPlaying else { return }
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
