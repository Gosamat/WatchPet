import UserNotifications
import Foundation

// MARK: - NotificationManager
// Handles local notifications on the Watch:
//   • "New Discovery!" when a species is first seen
//   • Care reminders (hunger / happiness low)
//   • Evolution ready alert
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error { print("[Notifications] Auth error: \(error)") }
                if granted { self.scheduleCareReminder() }
            }
    }

    // MARK: - New Species Discovery
    func scheduleDiscoveryNotification(speciesName: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Discovery! 🔬"
        content.body = "You encountered \(speciesName) for the first time! Check your Compendium."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id = "discovery_\(speciesName.lowercased().replacingOccurrences(of: " ", with: "_"))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Evolution Ready
    func scheduleEvolutionReadyNotification(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Evolution Ready! ✨"
        content.body = "\(petName) is ready to evolve. Open WatchPet to trigger it!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "evolution_ready", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Care Reminder (recurring every 4 hours)
    func scheduleCareReminder() {
        // Cancel any existing one first to avoid duplicates
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["care_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Your pet needs you! 🐾"
        content.body = "It might be hungry or unhappy. Give it some love."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 3600, repeats: true)
        let request = UNNotificationRequest(identifier: "care_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel all reminders
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
