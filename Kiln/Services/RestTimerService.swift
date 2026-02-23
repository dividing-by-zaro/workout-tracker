import Foundation
import UserNotifications
import SwiftUI

@Observable
final class RestTimerService {
    var isRunning: Bool = false
    var remainingSeconds: Int = 0
    var totalSeconds: Int = 90

    private var endDate: Date?
    private var displayTimer: Timer?
    private let notificationId = "rest-timer-notification"

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

        scheduleNotification(in: duration)
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

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
    }

    func syncFromPersistedState() {
        let storedTimestamp = UserDefaults.standard.double(forKey: Self.endDateKey)
        guard storedTimestamp > 0 else {
            isRunning = false
            return
        }

        let storedEndDate = Date(timeIntervalSince1970: storedTimestamp)
        totalSeconds = UserDefaults.standard.integer(forKey: Self.totalSecondsKey)
        if totalSeconds == 0 { totalSeconds = 90 }

        let remaining = storedEndDate.timeIntervalSinceNow
        if remaining > 0 {
            endDate = storedEndDate
            remainingSeconds = Int(ceil(remaining))
            isRunning = true
            startDisplayTimer()
        } else {
            stop()
            fireInAppAlert()
        }
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    @MainActor
    private func tick() {
        guard let endDate, isRunning else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            stop()
            fireInAppAlert()
        } else {
            remainingSeconds = Int(ceil(remaining))
        }
    }

    private func scheduleNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func fireInAppAlert() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
