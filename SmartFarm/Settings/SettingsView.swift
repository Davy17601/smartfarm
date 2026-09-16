import SwiftUI

/// Provides monthly income/expense data for the Settings chart
final class SettingsViewModel: ObservableObject {
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

/// Settings tab — language & currency preferences plus entry points to
/// Reports and Backup & Restore.
struct SettingsView: View {
    let environment: AppEnvironment

    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel: SettingsViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: SettingsViewModel(repository: environment.transactionRepository))
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(L("settings.preferences"))) {
                    Picker(L("settings.language"), selection: $localization.language) {
                        ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker(L("settings.displayCurrency"), selection: $settings.displayCurrency) {
                        ForEach(Currency.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }

                // Monthly Income/Expense Chart
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        IncomeExpenseBarChartView(totals: viewModel.monthlyTotals, currency: viewModel.currency)
                    }
                    .padding(.vertical, Theme.Spacing.s)
                }

                Section(header: Text(L("settings.data"))) {
                    NavigationLink {
                        ReportsView(repository: environment.transactionRepository)
                    } label: {
                        Label(L("settings.reports"), systemImage: "chart.bar.doc.horizontal")
                    }

                    NavigationLink {
                        BackupView(environment: environment)
                    } label: {
                        Label(L("settings.backup"), systemImage: "externaldrive")
                    }
                }

                Section(header: Text(L("settings.about"))) {
                    HStack {
                        Text(L("common.version"))
                        Spacer()
                        Text("1.0").foregroundColor(Theme.secondaryText)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(L("tab.settings"))
            .onAppear { viewModel.reload(currency: settings.displayCurrency) }
            .onChange(of: settings.displayCurrency) { viewModel.reload(currency: $0) }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Grouped Bar Chart Component

/// Grouped/paired bar chart showing income (green) vs expense (red) per month
/// Custom implementation for iOS 14 (Swift Charts requires iOS 16+)
struct IncomeExpenseBarChartView: View {
    let totals: [MonthlyTotal]
    let currency: Currency

    private var maxValue: Double {
        let allValues = totals.flatMap { [$0.income, $0.expense] }
        return max(allValues.max() ?? 0, 1)
    }

    var body: some View {
        if totals.isEmpty {
            Text(L("reports.noData")).foregroundColor(Theme.secondaryText)
        } else {
            VStack(spacing: Theme.Spacing.m) {
                // Title and Legend
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(L("settings.chartTitle"))
                        .font(Theme.Fonts.heading)
                        .foregroundColor(Theme.primaryText)

                    HStack(spacing: Theme.Spacing.m) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Rectangle()
                                .fill(Color(red: 0.13, green: 0.55, blue: 0.13))
                                .frame(width: 16, height: 16)
                                .cornerRadius(3)
                            Text(L("finance.income"))
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                        HStack(spacing: Theme.Spacing.xs) {
                            Rectangle()
                                .fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                                .frame(width: 16, height: 16)
                                .cornerRadius(3)
                            Text(L("finance.expense"))
                                .font(Theme.Fonts.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Chart
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis labels
                    yAxisLabels
                        .frame(width: 40)

                    // Bars
                    GeometryReader { geo in
                        HStack(alignment: .bottom, spacing: Theme.Spacing.xs) {
                            ForEach(totals) { total in
                                barGroup(for: total, maxHeight: geo.size.height)
                            }
                        }
                    }
                }
                .frame(height: 200)

                // X-axis labels (month names)
                HStack(spacing: Theme.Spacing.xs) {
                    Spacer().frame(width: 40) // Offset for Y-axis
                    ForEach(totals) { total in
                        Text(total.label)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var yAxisLabels: some View {
        VStack(alignment: .trailing) {
            ForEach(0..<5) { i in
                let value = maxValue * Double(4 - i) / 4
                Text(formatYAxisValue(value))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.secondaryText)
                if i < 4 {
                    Spacer()
                }
            }
        }
    }

    private func formatYAxisValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private func barGroup(for total: MonthlyTotal, maxHeight: CGFloat) -> some View {
        HStack(spacing: 2) {
            // Income bar (green)
            Rectangle()
                .fill(Color(red: 0.13, green: 0.55, blue: 0.13))
                .frame(height: barHeight(for: total.income, maxHeight: maxHeight))
                .cornerRadius(3)

            // Expense bar (red)
            Rectangle()
                .fill(Color(red: 0.8, green: 0.1, blue: 0.1))
                .frame(height: barHeight(for: total.expense, maxHeight: maxHeight))
                .cornerRadius(3)
        }
        .frame(maxWidth: .infinity)
    }

    private func barHeight(for value: Double, maxHeight: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return max(CGFloat(value / maxValue) * maxHeight, value > 0 ? 2 : 0)
    }
}
