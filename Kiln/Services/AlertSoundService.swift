import AVFoundation
import Foundation

enum AlertSound: String, CaseIterable, Identifiable {
    case `default` = "alert_tone"
    case spark = "Spark"
    case ember = "Ember"
    case kindle = "Kindle"
    case blaze = "Blaze"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .spark: return "Spark"
        case .ember: return "Ember"
        case .kindle: return "Kindle"
        case .blaze: return "Blaze"
        }
    }

    var fileName: String { "\(rawValue).caf" }
}

@MainActor
@Observable
final class AlertSoundService {
    private static let storageKey = "selectedAlertSound"

    var selected: AlertSound {
        didSet {
            UserDefaults.standard.set(selected.rawValue, forKey: Self.storageKey)
        }
    }

    private var previewPlayer: AVAudioPlayer?

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? AlertSound.default.rawValue
        self.selected = AlertSound(rawValue: stored) ?? .default
    }

    func preview(_ sound: AlertSound) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "caf") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            previewPlayer = player
        } catch {
            print("AlertSoundService: preview failed — \(error)")
        }
    }
}
