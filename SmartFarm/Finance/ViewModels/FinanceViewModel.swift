import Foundation
import Combine

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
    @Published var selectedCategory: TransactionCategory?
    @Published var searchText: String = ""

    private let repository: TransactionRepositoryProtocol

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
        reload()
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
    }

    func update(_ transaction: Transaction) {
        repository.update(transaction)
        reload()
    }

    func delete(_ transaction: Transaction) {
        repository.delete(id: transaction.id)
        reload()
    }

    /// Delete by offsets within the currently filtered list (List swipe-to-delete).
    func delete(at offsets: IndexSet) {
        let items = filteredTransactions
        offsets.compactMap { items.indices.contains($0) ? items[$0] : nil }
            .forEach { repository.delete(id: $0.id) }
        reload()
    }
}
