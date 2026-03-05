import AVFoundation
import Foundation

@MainActor
@Observable
final class BackgroundAudioService {
    private var audioPlayer: AVAudioPlayer?
    private var alertPlayer: AVAudioPlayer?
    private var shouldBePlaying = false
    private var interruptionObserver: Any?

    /// Whether silent audio is actually playing (checks real player state).
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    func startSilentAudio() {
        guard !isPlaying else { return }
        shouldBePlaying = true
        observeInterruptions()
        startPlayer()
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
        shouldBePlaying = false
        audioPlayer?.stop()
        audioPlayer = nil
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }

        if alertPlayer?.isPlaying != true {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Private

    private func startPlayer() {
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
        } catch {
            print("BackgroundAudioService: failed to start — \(error)")
        }
    }

    private func observeInterruptions() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard shouldBePlaying,
              let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            print("BackgroundAudioService: audio interrupted")
        case .ended:
            print("BackgroundAudioService: interruption ended, restarting")
            startPlayer()
        @unknown default:
            break
        }
    }
}
