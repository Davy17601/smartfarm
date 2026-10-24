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
    let category: String
    let amount: Double
    let percentage: Double
}

/// Builds the monthly profit/loss series for the reports screen.
final class ReportsViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var monthlyTotals: [MonthlyTotal] = []

    private(set) var currency: Currency = .khr
    let repository: TransactionRepositoryProtocol

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

        // Group by LOCALIZED category name and sum (fixes duplicate category issue)
        var categoryTotals: [String: Double] = [:]
        for tx in expenses {
            let localizedName = TransactionCategory.localizedName(for: tx.category)
            categoryTotals[localizedName, default: 0] += tx.amount
        }

        // Convert to breakdown with percentages, sorted by amount descending
        let allCategories = categoryTotals.map { category, amount in
            CategoryBreakdown(
                category: category,
                amount: amount,
                percentage: (amount / total) * 100
            )
        }.sorted { $0.amount > $1.amount }

        // Limit to top 6 categories, group the rest into "ផ្សេងៗ"
        let maxCategories = 6
        if allCategories.count <= maxCategories {
            return allCategories
        }

        let topCategories = Array(allCategories.prefix(maxCategories))
        let otherCategories = Array(allCategories.dropFirst(maxCategories))
        let otherTotal = otherCategories.reduce(0.0) { $0 + $1.amount }
        let otherPercentage = (otherTotal / total) * 100

        if otherTotal > 0 {
            return topCategories + [CategoryBreakdown(
                category: "ផ្សេងៗ",
                amount: otherTotal,
                percentage: otherPercentage
            )]
        }

        return topCategories
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
