import Foundation
import UserNotifications

/// Wraps `UNUserNotificationCenter` for local reminders.
/// Schedules two notifications per item — one day before and one on the day.
/// Works even when the app is closed (local notifications are OS-scheduled).
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// The id of the item whose notification the user last tapped — observed by
    /// the relevant module to deep-link to that item.
    @Published var tappedItemID: UUID?

    private let center = UNUserNotificationCenter.current()
    private static let userInfoKey = "itemID"

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    /// Schedule (or reschedule) reminders for an item at `date`.
    /// Past fire dates are skipped.
    func schedule(id: UUID, title: String, body: String, date: Date) {
        cancel(id: id)
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date)
        scheduleOne(suffix: "before", id: id, title: title,
                    body: L("notif.tomorrow") + body, fireDate: dayBefore)
        scheduleOne(suffix: "day", id: id, title: title, body: body, fireDate: date)
    }

    func cancel(id: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["\(id.uuidString)-before", "\(id.uuidString)-day"]
        )
    }

    // MARK: - Private

    private func scheduleOne(suffix: String, id: UUID, title: String, body: String, fireDate: Date?) {
        guard let fireDate = fireDate, fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [Self.userInfoKey: id.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(id.uuidString)-\(suffix)", content: content, trigger: trigger
        )
        center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound]) // show even while foregrounded (iOS 14+)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let raw = response.notification.request.content.userInfo[Self.userInfoKey] as? String,
           let id = UUID(uuidString: raw) {
            DispatchQueue.main.async { self.tappedItemID = id }
        }
        completionHandler()
    }
}
