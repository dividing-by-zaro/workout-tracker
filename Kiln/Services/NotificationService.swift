import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private static let restTimerIdentifier = "restTimer"
    private(set) var isPermissionGranted = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in
                self.isPermissionGranted = granted
            }
        }
    }

    func scheduleRestTimer(duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alert_tone.caf"))

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
        // Suppress banner/sound in foreground — the in-app timer expiry handler
        // already plays alert_tone.caf and fires haptic
        completionHandler([])
    }
}
