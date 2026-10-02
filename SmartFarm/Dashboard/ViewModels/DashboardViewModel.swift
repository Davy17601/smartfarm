import Foundation

/// Drives the home Dashboard: today's schedule and the upcoming week of
/// farm activities & reminders.
final class DashboardViewModel: ObservableObject {
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []

    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol
    private let notifications: NotificationService

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol,
         notifications: NotificationService = .shared) {
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
        self.notifications = notifications
        reload()
    }

    func reload() {
        activities = activityRepository.fetchAll()
        reminders = reminderRepository.fetchAll()
    }

    // MARK: - Today

    func todayActivities() -> [FarmActivity] {
        activities
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    func todayReminders() -> [Reminder] {
        reminders
            .filter { Calendar.current.isDateInToday($0.dueDate) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Whether any activity or reminder falls on the given day — used by the week strip.
    func hasSchedule(on date: Date) -> Bool {
        let calendar = Calendar.current
        return activities.contains { calendar.isDate($0.date, inSameDayAs: date) }
            || reminders.contains { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    // MARK: - Upcoming (from tomorrow, within `days`)

    func upcomingActivities(within days: Int = 7) -> [FarmActivity] {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
        let future = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return activities
            .filter { !$0.isCompleted && $0.date >= startOfTomorrow && $0.date <= future }
            .sorted { $0.date < $1.date }
    }

    func upcomingReminders(within days: Int = 7) -> [Reminder] {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
        let future = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return reminders
            .filter { !$0.isCompleted && $0.dueDate >= startOfTomorrow && $0.dueDate <= future }
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
}
