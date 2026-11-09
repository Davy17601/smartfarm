import Foundation
import Combine
import UIKit

/// Drives the home Dashboard: today's schedule and the upcoming week of
/// farm activities & reminders.
final class DashboardViewModel: ObservableObject {
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []

    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol
    private let notifications: NotificationService
    private var cancellables = Set<AnyCancellable>()

    /// Bumped whenever the calendar day rolls over (midnight, or a timezone or
    /// clock change). Nothing reads the value: publishing it re-renders the
    /// views whose "today" is derived from `Date()` at render time — the week
    /// strip's highlighted day and the "today's schedule" date label — which
    /// SwiftUI would otherwise leave showing the day the app launched on.
    @Published private(set) var currentDay: Date = Calendar.current.startOfDay(for: Date())

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol,
         notifications: NotificationService = .shared) {
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
        self.notifications = notifications
        reload()
        observeSignificantTimeChanges()
    }

    /// Re-reads the current day and reloads, so the Dashboard's "today" follows
    /// the device clock while the app stays running.
    func refreshForCurrentDate() {
        let today = Calendar.current.startOfDay(for: Date())
        guard today != currentDay else { return }
        currentDay = today
        reload()
    }

    private func observeSignificantTimeChanges() {
        NotificationCenter.default
            .publisher(for: UIApplication.significantTimeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshForCurrentDate() }
            .store(in: &cancellables)
    }

    func reload() {
        activities = activityRepository.fetchAll()
        reminders = reminderRepository.fetchAll()
    }

    // MARK: - Schedule window (today through `days` days ahead, inclusive)

    /// Not-yet-completed activities from today through `days` days ahead —
    /// backs the Home screen's "upcoming schedule" list, where a today item
    /// gets its own "ថ្ងៃនេះ" pill rather than a separate today section.
    func scheduleActivities(within days: Int = 7) -> [FarmActivity] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: days, to: startOfToday) ?? startOfToday
        return activities
            .filter { !$0.isCompleted && $0.date >= startOfToday && $0.date < end }
            .sorted { $0.date < $1.date }
    }

    func scheduleReminders(within days: Int = 7) -> [Reminder] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: days, to: startOfToday) ?? startOfToday
        return reminders
            .filter { !$0.isCompleted && $0.dueDate >= startOfToday && $0.dueDate < end }
            .sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Quick add

    func addActivity(_ activity: FarmActivity) {
        activityRepository.add(activity)
        notifications.schedule(id: activity.id, title: L("notif.activity"), body: activity.title, date: activity.date)
        reload()
    }

    func addReminder(_ reminder: Reminder) {
        reminderRepository.add(reminder)
        notifications.schedule(id: reminder.id, title: L("notif.reminder"), body: reminder.title, date: reminder.dueDate)
        reload()
    }

    // MARK: - Edit (from a tapped schedule row)

    func updateActivity(_ activity: FarmActivity) {
        activityRepository.update(activity)
        scheduleOrCancel(id: activity.id, title: L("notif.activity"), body: activity.title,
                          date: activity.date, isCompleted: activity.isCompleted)
        reload()
    }

    func updateReminder(_ reminder: Reminder) {
        reminderRepository.update(reminder)
        scheduleOrCancel(id: reminder.id, title: L("notif.reminder"), body: reminder.title,
                          date: reminder.dueDate, isCompleted: reminder.isCompleted)
        reload()
    }

    private func scheduleOrCancel(id: UUID, title: String, body: String, date: Date, isCompleted: Bool) {
        if isCompleted {
            notifications.cancel(id: id)
        } else {
            notifications.schedule(id: id, title: title, body: body, date: date)
        }
    }
}
