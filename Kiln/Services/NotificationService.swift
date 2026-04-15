import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private static let restTimerIdentifier = "restTimer"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleRestTimer(duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set!"
        let soundName = UserDefaults.standard.string(forKey: "selectedAlertSound") ?? "alert_tone"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundName).caf"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(duration), repeats: false)
        let request = UNNotificationRequest(identifier: Self.restTimerIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("NotificationService: failed to schedule — \(error)")
            }
        }
    }

    func cancelRestTimer() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.restTimerIdentifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Self.restTimerIdentifier])
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Foreground: play sound, suppress banner (user is looking at the active workout UI)
        completionHandler([.sound])
    }
}
