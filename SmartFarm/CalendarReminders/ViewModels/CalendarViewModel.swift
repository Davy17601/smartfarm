import Foundation
import Combine
import UIKit

/// Drives the Calendar & Reminders tab. Manages farm activities (date-based tasks)
/// and reminders, schedules local notifications, and reacts to notification taps
/// by selecting the tapped item's date.
final class CalendarViewModel: ObservableObject {
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []
    /// The day the grid has selected. Seeded to today, and re-seeded by
    /// `refreshForCurrentDate()` once the calendar day rolls over.
    @Published var selectedDate: Date = Date() {
        didSet { selectionMadeOnDay = Calendar.current.startOfDay(for: Date()) }
    }

    /// Start of the day on which `selectedDate` was last set, in the device's
    /// own calendar and timezone. This view model is a `@StateObject` owned by
    /// a `TabView`, so it lives as long as the app process: without this, the
    /// date seeded at launch keeps masquerading as "today" after the app sits
    /// backgrounded past midnight, and the grid circles yesterday.
    private var selectionMadeOnDay: Date = Calendar.current.startOfDay(for: Date())

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
        observeSignificantTimeChanges()
    }

    /// Snaps the selection back to the real current date when the calendar day
    /// has rolled over since that selection was made — the app resuming past
    /// midnight, or the device timezone/clock changing. A selection made
    /// earlier *today* is left alone, so switching tabs never discards a date
    /// the user deliberately picked.
    func refreshForCurrentDate() {
        guard Calendar.current.startOfDay(for: Date()) != selectionMadeOnDay else { return }
        selectedDate = Date()
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

    // MARK: - Notifications tab (ខាងមុខ / ហួសកំណត់ / បានធ្វើរួច)

    /// "ខាងមុខ" — not yet completed, due now or later, soonest first. Also
    /// backs the Calendar tab's notification-bell dot.
    var upcomingNotificationItems: [AgendaItem] {
        let now = Date()
        let activityItems = activities.filter { !$0.isCompleted && $0.date >= now }.map(AgendaItem.activity)
        let reminderItems = reminders.filter { !$0.isCompleted && $0.dueDate >= now }.map(AgendaItem.reminder)
        return (activityItems + reminderItems).sorted { $0.date < $1.date }
    }

    /// "ហួសកំណត់" — not yet completed, due date/time already passed, most
    /// recently overdue first.
    var overdueNotificationItems: [AgendaItem] {
        let now = Date()
        let activityItems = activities.filter { !$0.isCompleted && $0.date < now }.map(AgendaItem.activity)
        let reminderItems = reminders.filter { !$0.isCompleted && $0.dueDate < now }.map(AgendaItem.reminder)
        return (activityItems + reminderItems).sorted { $0.date > $1.date }
    }

    /// "បានធ្វើរួច" — marked done (any date), most recently completed first.
    var completedNotificationItems: [AgendaItem] {
        let activityItems = activities.filter { $0.isCompleted }.map(AgendaItem.activity)
        let reminderItems = reminders.filter { $0.isCompleted }.map(AgendaItem.reminder)
        return (activityItems + reminderItems).sorted { $0.completedSortDate > $1.completedSortDate }
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
        updated.completedAt = updated.isCompleted ? Date() : nil
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
        updated.completedAt = updated.isCompleted ? Date() : nil
        updateReminder(updated)
    }

    /// Unified toggle for the Notifications tab's checkbox/checkmark — marks
    /// done (moves to "បានធ្វើរួច") or undoes it (moves back), whichever
    /// `item` currently needs. `updateActivity`/`updateReminder` already
    /// cancel the pending local notification when completed and reschedule
    /// it when undone (`scheduleNotification` skips past fire dates on its
    /// own, so undoing an overdue item safely schedules nothing).
    func toggleCompleted(_ item: AgendaItem) {
        switch item {
        case .activity(let activity): toggleActivityCompleted(activity)
        case .reminder(let reminder): toggleReminderCompleted(reminder)
        }
    }

    func deleteReminder(_ reminder: Reminder) {
        notifications.cancel(id: reminder.id)
        reminderRepository.delete(id: reminder.id)
        reload()
    }

    /// Unified delete for the Notifications tab's swipe-to-delete action.
    func deleteItem(_ item: AgendaItem) {
        switch item {
        case .activity(let activity): deleteActivity(activity)
        case .reminder(let reminder): deleteReminder(reminder)
        }
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

    /// `UIApplication.significantTimeChangeNotification` fires at midnight and
    /// on timezone/clock changes — the moments at which a cached "today" goes
    /// stale while the app is still running.
    private func observeSignificantTimeChanges() {
        NotificationCenter.default
            .publisher(for: UIApplication.significantTimeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshForCurrentDate() }
            .store(in: &cancellables)
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
