import Foundation

/// Income / expense totals for a single calendar month.
/// Kept for `MonthlyBarChartView` and the finance CSV/PDF export path in
/// `ReportExporter`, though the Reports screen itself no longer uses it.
struct MonthlyTotal: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let income: Double
    let expense: Double
    var profit: Double { income - expense }
}

/// Farm activity count for a single calendar month.
struct MonthlyActivityCount: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let count: Int
}

/// Builds the monthly activity-count series and the completed/upcoming
/// summary for the reports screen, from farm activities and reminders.
final class ReportsViewModel: ObservableObject {
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []
    @Published private(set) var monthlyActivityCounts: [MonthlyActivityCount] = []

    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol

    init(activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
    }

    func reload() {
        activities = activityRepository.fetchAll()
        reminders = reminderRepository.fetchAll()
        monthlyActivityCounts = computeMonthlyActivityCounts(monthsBack: 6)
    }

    // MARK: - Completed / upcoming summary

    var completedActivitiesCount: Int { activities.filter { $0.isCompleted }.count }
    var upcomingActivitiesCount: Int { activities.filter { !$0.isCompleted && $0.date >= Date() }.count }
    var completedRemindersCount: Int { reminders.filter { $0.isCompleted }.count }
    var upcomingRemindersCount: Int { reminders.filter { !$0.isCompleted && $0.dueDate >= Date() }.count }

    // MARK: - Activity category breakdown

    /// Activity counts per `FarmActivityCategory`, in enum declaration order.
    var activityCategoryCounts: [(category: FarmActivityCategory, count: Int)] {
        FarmActivityCategory.allCases.map { category in
            (category, activities.filter { $0.category == category }.count)
        }
    }

    // MARK: - Private

    private func computeMonthlyActivityCounts(monthsBack: Int) -> [MonthlyActivityCount] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")

        let now = Date()

        return (0..<monthsBack).reversed().compactMap { offset -> MonthlyActivityCount? in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now),
                  let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start
            else { return nil }

            let count = activities.filter {
                calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }.count
            return MonthlyActivityCount(monthStart: monthStart,
                                        label: formatter.string(from: monthDate),
                                        count: count)
        }
    }
}
