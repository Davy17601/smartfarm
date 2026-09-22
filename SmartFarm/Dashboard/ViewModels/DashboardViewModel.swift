import Foundation
import Combine

/// Category breakdown for Dashboard pie chart
struct DashboardCategoryBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
}

/// Aggregates data from all repositories for the home Dashboard:
/// current-month profit/loss, latest transactions, and upcoming items.
final class DashboardViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var activities: [FarmActivity] = []
    @Published private(set) var reminders: [Reminder] = []

    private let transactionRepository: TransactionRepositoryProtocol
    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(transactionRepository: TransactionRepositoryProtocol,
         activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
        reload()

        // Listen for transaction changes from other ViewModels (e.g., FinanceViewModel)
        NotificationCenter.default.publisher(for: .transactionDataDidChange)
            .sink { [weak self] _ in
                self?.reloadTransactions()
            }
            .store(in: &cancellables)
    }

    func reload() {
        transactions = transactionRepository.fetchAll()
        activities = activityRepository.fetchAll()
        reminders = reminderRepository.fetchAll()
    }

    func reloadTransactions() {
        transactions = transactionRepository.fetchAll()
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

    /// All transactions for full history view
    var allTransactions: [Transaction] { transactions }

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

    // MARK: - Urgency helpers

    /// Returns localized urgency badge label for a date ("ថ្ងៃនេះ", "ស្អែក", or nil).
    func urgencyBadge(for date: Date) -> String? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return L("dashboard.today")
        } else if calendar.isDateInTomorrow(date) {
            return L("dashboard.tomorrow")
        }
        return nil
    }

    // MARK: - Transaction management

    /// Delete a specific transaction
    func deleteTransaction(_ transaction: Transaction) {
        transactionRepository.delete(id: transaction.id)
        reloadTransactions()
        // Notify other ViewModels that data changed
        NotificationCenter.default.post(name: .transactionDataDidChange, object: nil)
    }

    /// Delete the most recently added transaction
    func deleteLastTransaction() {
        guard let lastTransaction = transactions.first else { return }
        deleteTransaction(lastTransaction)
    }

    /// Clear old transactions (older than 30 days)
    func clearOldTransactions() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let oldTransactions = transactions.filter { $0.date < thirtyDaysAgo }
        for transaction in oldTransactions {
            transactionRepository.delete(id: transaction.id)
        }
        reloadTransactions()
        // Notify other ViewModels that data changed
        NotificationCenter.default.post(name: .transactionDataDidChange, object: nil)
    }

    // MARK: - Activity management

    /// Update an existing farm activity
    func updateActivity(_ activity: FarmActivity) {
        activityRepository.update(activity)
        reload()
    }

    /// Delete a specific farm activity
    func deleteActivity(_ activity: FarmActivity) {
        activityRepository.delete(id: activity.id)
        reload()
    }

    // MARK: - Category breakdown for pie chart

    /// Computes category breakdown for expenses in the selected currency
    func categoryBreakdown(in currency: Currency) -> [DashboardCategoryBreakdown] {
        let expenses = transactions.filter { $0.type == .expense && $0.currency == currency }
        let total = expenses.reduce(0.0) { $0 + $1.amount }

        guard total > 0 else { return [] }

        // Group by category and sum
        var categoryTotals: [String: Double] = [:]
        for tx in expenses {
            categoryTotals[tx.category, default: 0] += tx.amount
        }

        // Convert to breakdown with percentages, using localized category names
        return categoryTotals.map { category, amount in
            DashboardCategoryBreakdown(
                category: TransactionCategory.localizedName(for: category),
                amount: amount,
                percentage: (amount / total) * 100
            )
        }.sorted { $0.amount > $1.amount } // Sort by amount descending
    }
}
