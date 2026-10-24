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
    @Published var selectedMonth: Date = Date()

    private(set) var currency: Currency = .khr
    let repository: TransactionRepositoryProtocol

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    func reload(currency: Currency) {
        self.currency = currency
        transactions = repository.fetchAll()
        reloadForSelectedMonth()
    }

    func reloadForSelectedMonth() {
        monthlyTotals = computeMonthlyTotals(for: selectedMonth)
    }

    // MARK: - Month Navigation

    func previousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
            reloadForSelectedMonth()
        }
    }

    func nextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            // Don't allow going past the current month
            if !calendar.isDate(newDate, equalTo: Date(), toGranularity: .month) &&
               newDate < Date() {
                selectedMonth = newDate
                reloadForSelectedMonth()
            } else if calendar.isDate(newDate, equalTo: Date(), toGranularity: .month) {
                selectedMonth = newDate
                reloadForSelectedMonth()
            }
        }
    }

    func canGoToNextMonth() -> Bool {
        let calendar = Calendar.current
        return !calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Month Data

    func selectedMonthData() -> (income: Double, expense: Double, profit: Double) {
        let calendar = Calendar.current
        let inCurrency = transactions.filter { $0.currency == currency }
        let monthTx = inCurrency.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
        let income = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return (income: income, expense: expense, profit: income - expense)
    }

    func previousMonthData() -> (income: Double, expense: Double, profit: Double)? {
        let calendar = Calendar.current
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else {
            return nil
        }

        let inCurrency = transactions.filter { $0.currency == currency }
        let monthTx = inCurrency.filter {
            calendar.isDate($0.date, equalTo: prevMonth, toGranularity: .month)
        }

        // Return nil if no data in previous month
        if monthTx.isEmpty {
            return nil
        }

        let income = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return (income: income, expense: expense, profit: income - expense)
    }

    /// Computes category breakdown for expenses in the selected currency and month
    func categoryBreakdown() -> [CategoryBreakdown] {
        let calendar = Calendar.current
        let expenses = transactions.filter {
            $0.type == .expense &&
            $0.currency == currency &&
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
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

    private func computeMonthlyTotals(for month: Date) -> [MonthlyTotal] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "km")
        formatter.dateFormat = "d" // Day number for weekly groupings

        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        let inCurrency = transactions.filter {
            $0.currency == currency &&
            $0.date >= monthInterval.start && $0.date < monthInterval.end
        }

        // Group by week within the month
        var weeklyTotals: [MonthlyTotal] = []
        var currentWeekStart = monthInterval.start

        while currentWeekStart < monthInterval.end {
            let weekEnd = min(
                calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? monthInterval.end,
                monthInterval.end
            )

            let weekTx = inCurrency.filter {
                $0.date >= currentWeekStart && $0.date < weekEnd
            }

            let income = weekTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = weekTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

            // Format label as date range (e.g., "1-7")
            let startDay = calendar.component(.day, from: currentWeekStart)
            let endDay = calendar.component(.day, from: calendar.date(byAdding: .day, value: -1, to: weekEnd) ?? currentWeekStart)

            let label: String
            if startDay == endDay {
                label = "\(startDay)"
            } else {
                label = "\(startDay)-\(endDay)"
            }

            weeklyTotals.append(MonthlyTotal(
                monthStart: currentWeekStart,
                label: label,
                income: income,
                expense: expense
            ))

            currentWeekStart = weekEnd
        }

        return weeklyTotals
    }
}
