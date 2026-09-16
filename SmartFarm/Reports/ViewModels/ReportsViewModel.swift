import Foundation
import SwiftUI

/// Income / expense totals for a single calendar month.
struct MonthlyTotal: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let income: Double
    let expense: Double
    var profit: Double { income - expense }
}

/// Category breakdown for pie chart
struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
}

/// Builds the monthly profit/loss series for the reports screen.
final class ReportsViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var monthlyTotals: [MonthlyTotal] = []

    private(set) var currency: Currency = .khr
    private let repository: TransactionRepositoryProtocol

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    func reload(currency: Currency) {
        self.currency = currency
        transactions = repository.fetchAll()
        monthlyTotals = computeMonthlyTotals(monthsBack: 6)
    }

    /// Computes category breakdown for expenses in the selected currency
    func categoryBreakdown() -> [CategoryBreakdown] {
        let expenses = transactions.filter { $0.type == .expense && $0.currency == currency }
        let total = expenses.reduce(0.0) { $0 + $1.amount }

        guard total > 0 else { return [] }

        // Group by category and sum
        var categoryTotals: [TransactionCategory: Double] = [:]
        for tx in expenses {
            categoryTotals[tx.category, default: 0] += tx.amount
        }

        // Convert to breakdown with percentages
        return categoryTotals.map { category, amount in
            CategoryBreakdown(
                category: category,
                amount: amount,
                percentage: (amount / total) * 100
            )
        }.sorted { $0.amount > $1.amount } // Sort by amount descending
    }

    private func computeMonthlyTotals(monthsBack: Int) -> [MonthlyTotal] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")

        let now = Date()
        let inCurrency = transactions.filter { $0.currency == currency }

        return (0..<monthsBack).reversed().compactMap { offset -> MonthlyTotal? in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now),
                  let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start
            else { return nil }

            let monthTx = inCurrency.filter {
                calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            let income = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return MonthlyTotal(monthStart: monthStart,
                                label: formatter.string(from: monthDate),
                                income: income, expense: expense)
        }
    }
}
