import Foundation

/// Income / expense totals for a single calendar month.
struct MonthlyTotal: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let income: Double
    let expense: Double
    var profit: Double { income - expense }
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
