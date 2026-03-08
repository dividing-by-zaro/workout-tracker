import AVFoundation
import Foundation

@MainActor
@Observable
final class BackgroundAudioService {
    private var alertPlayer: AVAudioPlayer?

    func playAlertSound() {
        guard let url = Bundle.main.url(forResource: "alert_tone", withExtension: "caf") else {
            print("BackgroundAudioService: alert_tone.caf not found in bundle")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            alertPlayer = player
        } catch {
            print("BackgroundAudioService: failed to play alert — \(error)")
        }
    }
}
