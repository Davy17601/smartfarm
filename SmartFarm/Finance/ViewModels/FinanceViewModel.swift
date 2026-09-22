import Foundation
import Combine

// Notification name for transaction data changes
extension Notification.Name {
    static let transactionDataDidChange = Notification.Name("transactionDataDidChange")
}

/// Type filter applied to the transaction list.
enum TransactionFilter: String, CaseIterable, Identifiable {
    case all, income, expense
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .all:     return L("common.all")
        case .income:  return L("finance.income")
        case .expense: return L("finance.expense")
        }
    }
}

/// Drives the Finance tab. Publishes domain structs; delegates persistence to the
/// repository so it can be unit-tested with a mock conforming to
/// `TransactionRepositoryProtocol`.
final class FinanceViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published var filter: TransactionFilter = .all
    @Published var selectedCategory: String?
    @Published var searchText: String = ""

    private let repository: TransactionRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
        reload()

        // Listen for transaction changes from other ViewModels
        NotificationCenter.default.publisher(for: .transactionDataDidChange)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    func reload() {
        transactions = repository.fetchAll()
    }

    // MARK: - Derived data

    var filteredTransactions: [Transaction] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return transactions.filter { t in
            let matchesType: Bool
            switch filter {
            case .all:     matchesType = true
            case .income:  matchesType = t.type == .income
            case .expense: matchesType = t.type == .expense
            }
            let matchesCategory = selectedCategory == nil || t.category == selectedCategory
            let matchesSearch = query.isEmpty
                || t.title.localizedCaseInsensitiveContains(query)
                || t.note.localizedCaseInsensitiveContains(query)
            return matchesType && matchesCategory && matchesSearch
        }
    }

    // MARK: - Current Month Calculations (synced with Dashboard)

    /// Returns income for the current month in the specified currency
    func monthIncome(in currency: Currency) -> Double {
        monthTransactions(in: currency).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    /// Returns expense for the current month in the specified currency
    func monthExpense(in currency: Currency) -> Double {
        monthTransactions(in: currency).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    /// Returns profit (income - expense) for the current month in the specified currency
    func monthProfit(in currency: Currency) -> Double {
        monthIncome(in: currency) - monthExpense(in: currency)
    }

    /// Filters transactions to only those in the current month with the specified currency
    private func monthTransactions(in currency: Currency) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
                && $0.currency == currency
        }
    }

    // MARK: - Specific Month Calculations (for Finance tab month selector)

    /// Returns income for a specific month in the specified currency
    func monthIncome(for date: Date, in currency: Currency) -> Double {
        monthTransactions(for: date, in: currency).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    /// Returns expense for a specific month in the specified currency
    func monthExpense(for date: Date, in currency: Currency) -> Double {
        monthTransactions(for: date, in: currency).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    /// Returns profit (income - expense) for a specific month in the specified currency
    func monthProfit(for date: Date, in currency: Currency) -> Double {
        monthIncome(for: date, in: currency) - monthExpense(for: date, in: currency)
    }

    /// Filters transactions to only those in the specified month with the specified currency
    private func monthTransactions(for date: Date, in currency: Currency) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
                && $0.currency == currency
        }
    }

    // MARK: - All-Time Calculations (kept for reference/future use)

    func totalIncome(in currency: Currency) -> Double { sum(.income, currency) }
    func totalExpense(in currency: Currency) -> Double { sum(.expense, currency) }
    func profit(in currency: Currency) -> Double {
        totalIncome(in: currency) - totalExpense(in: currency)
    }

    private func sum(_ type: TransactionType, _ currency: Currency) -> Double {
        transactions
            .filter { $0.type == type && $0.currency == currency }
            .reduce(0) { $0 + $1.amount }
    }

    func transaction(for id: UUID) -> Transaction? {
        transactions.first { $0.id == id }
    }

    // MARK: - Mutations

    func add(_ transaction: Transaction) {
        repository.add(transaction)
        reload()
        // Notify other ViewModels that data changed
        NotificationCenter.default.post(name: .transactionDataDidChange, object: nil)
    }

    func update(_ transaction: Transaction) {
        repository.update(transaction)
        reload()
        // Notify other ViewModels that data changed
        NotificationCenter.default.post(name: .transactionDataDidChange, object: nil)
    }

    func delete(_ transaction: Transaction) {
        repository.delete(id: transaction.id)
        reload()
        // Notify other ViewModels that data changed
        NotificationCenter.default.post(name: .transactionDataDidChange, object: nil)
    }

    /// Delete by offsets within the currently filtered list (List swipe-to-delete).
    func delete(at offsets: IndexSet) {
        let items = filteredTransactions
        offsets.compactMap { items.indices.contains($0) ? items[$0] : nil }
            .forEach { repository.delete(id: $0.id) }
        reload()
        // Notify other ViewModels that data changed
        NotificationCenter.default.post(name: .transactionDataDidChange, object: nil)
    }
}
