import Foundation

/// Aggregates data from all repositories for the home Dashboard:
/// current-month profit/loss, latest transactions, and upcoming items.
final class DashboardViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []

    private let transactionRepository: TransactionRepositoryProtocol
    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol,
         activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
        reload()
    }

    func reload() {
        transactions = transactionRepository.fetchAll()
        activities = activityRepository.fetchAll()
        reminders = reminderRepository.fetchAll()
    }

    // MARK: - This month

    private func monthTransactions(in currency: Currency) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
                && $0.currency == currency
        }
    }

    func monthIncome(in currency: Currency) -> Double {
        monthTransactions(in: currency).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    func monthExpense(in currency: Currency) -> Double {
        monthTransactions(in: currency).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func monthProfit(in currency: Currency) -> Double {
        monthIncome(in: currency) - monthExpense(in: currency)
    }

    // MARK: - Lists

    /// Repository returns newest-first; take the most recent few.
    var latestTransactions: [Transaction] { Array(transactions.prefix(5)) }

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
}
