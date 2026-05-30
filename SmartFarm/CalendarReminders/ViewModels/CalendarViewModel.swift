import Foundation
import Combine

/// Drives the Calendar & Reminders tab. Manages farm activities (date-based tasks)
/// and reminders, schedules local notifications, and reacts to notification taps
/// by selecting the tapped item's date.
final class CalendarViewModel: ObservableObject {
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []
    @Published var selectedDate: Date = Date()

    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol
    private let notifications: NotificationService
    private var cancellables = Set<AnyCancellable>()

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol,
         notifications: NotificationService = .shared) {
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
        self.notifications = notifications
        reload()
        notifications.requestAuthorization()
        observeNotificationTaps()
    }

    func reload() {
        activities = activityRepository.fetchAll()
        reminders = reminderRepository.fetchAll()
    }

    // MARK: - Derived data

    func activities(on date: Date) -> [FarmActivity] {
        activities.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func upcomingActivities(within days: Int = 7) -> [FarmActivity] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        return activities
            .filter { !$0.isCompleted && $0.date >= now && $0.date <= future }
            .sorted { $0.date < $1.date }
    }

    func upcomingReminders(within days: Int = 7) -> [Reminder] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        return reminders
            .filter { !$0.isCompleted && $0.dueDate >= now && $0.dueDate <= future }
            .sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Activity CRUD

    func addActivity(_ activity: FarmActivity) {
        activityRepository.add(activity)
        scheduleNotification(id: activity.id, title: L("notif.activity"),
                             body: activity.title, date: activity.date,
                             isCompleted: activity.isCompleted)
        reload()
    }

    func updateActivity(_ activity: FarmActivity) {
        activityRepository.update(activity)
        scheduleNotification(id: activity.id, title: L("notif.activity"),
                             body: activity.title, date: activity.date,
                             isCompleted: activity.isCompleted)
        reload()
    }

    func toggleActivityCompleted(_ activity: FarmActivity) {
        var updated = activity
        updated.isCompleted.toggle()
        updateActivity(updated)
    }

    func deleteActivity(_ activity: FarmActivity) {
        notifications.cancel(id: activity.id)
        activityRepository.delete(id: activity.id)
        reload()
    }

    // MARK: - Reminder CRUD

    func addReminder(_ reminder: Reminder) {
        reminderRepository.add(reminder)
        scheduleNotification(id: reminder.id, title: L("notif.reminder"),
                             body: reminder.title, date: reminder.dueDate,
                             isCompleted: reminder.isCompleted)
        reload()
    }

    func updateReminder(_ reminder: Reminder) {
        reminderRepository.update(reminder)
        scheduleNotification(id: reminder.id, title: L("notif.reminder"),
                             body: reminder.title, date: reminder.dueDate,
                             isCompleted: reminder.isCompleted)
        reload()
    }

    func toggleReminderCompleted(_ reminder: Reminder) {
        var updated = reminder
        updated.isCompleted.toggle()
        updateReminder(updated)
    }

    func deleteReminder(_ reminder: Reminder) {
        notifications.cancel(id: reminder.id)
        reminderRepository.delete(id: reminder.id)
        reload()
    }

    // MARK: - Private

    private func scheduleNotification(id: UUID, title: String, body: String,
                                      date: Date, isCompleted: Bool) {
        if isCompleted {
            notifications.cancel(id: id)
        } else {
            notifications.schedule(id: id, title: title, body: body, date: date)
        }
    }

    private func observeNotificationTaps() {
        notifications.$tappedItemID
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                guard let self = self else { return }
                if let activity = self.activities.first(where: { $0.id == id }) {
                    self.selectedDate = activity.date
                } else if let reminder = self.reminders.first(where: { $0.id == id }) {
                    self.selectedDate = reminder.dueDate
                }
            }
            .store(in: &cancellables)
    }
}
