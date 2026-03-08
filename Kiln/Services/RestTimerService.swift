import Foundation
import SwiftUI

@MainActor
@Observable
final class RestTimerService {
    var isRunning: Bool = false
    var remainingSeconds: Int = 0
    var totalSeconds: Int = 120
    /// Called when timer expires. Bool parameter: `true` = live expiry, `false` = found-expired on restore.
    var onTimerExpired: ((_ playSound: Bool) -> Void)?

    private(set) var endDate: Date?
    private var displayTimer: Timer?

    private static let endDateKey = "restTimerEndDate"
    private static let totalSecondsKey = "restTimerTotalSeconds"

    func start(duration: Int) {
        stop()
        totalSeconds = duration
        endDate = Date.now.addingTimeInterval(Double(duration))
        remainingSeconds = duration
        isRunning = true

        UserDefaults.standard.set(endDate!.timeIntervalSince1970, forKey: Self.endDateKey)
        UserDefaults.standard.set(totalSeconds, forKey: Self.totalSecondsKey)

        startDisplayTimer()
    }

    func stop() {
        isRunning = false
        remainingSeconds = 0
        endDate = nil
        displayTimer?.invalidate()
        displayTimer = nil

        UserDefaults.standard.removeObject(forKey: Self.endDateKey)
        UserDefaults.standard.removeObject(forKey: Self.totalSecondsKey)
    }

    func syncFromPersistedState() {
        let storedTimestamp = UserDefaults.standard.double(forKey: Self.endDateKey)
        guard storedTimestamp > 0 else {
            isRunning = false
            return
        }

        let storedEndDate = Date(timeIntervalSince1970: storedTimestamp)
        totalSeconds = UserDefaults.standard.integer(forKey: Self.totalSecondsKey)
        if totalSeconds == 0 { totalSeconds = 120 }

        let remaining = storedEndDate.timeIntervalSinceNow
        if remaining > 0 {
            endDate = storedEndDate
            remainingSeconds = Int(ceil(remaining))
            isRunning = true
            startDisplayTimer()
        } else {
            stop()
            // Timer expired while app was dead — local notification already alerted
            onTimerExpired?(false)
        }
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    @MainActor
    private func tick() {
        guard let endDate, isRunning else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            stop()
            fireInAppAlert()
            onTimerExpired?(true)
        } else {
            remainingSeconds = Int(ceil(remaining))
        }
    }

    private func fireInAppAlert() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
