import SwiftUI

/// Detailed profit analysis screen showing monthly profit breakdown and category contributions
struct ProfitAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var settings: AppSettings
    let repository: TransactionRepositoryProtocol

    @State private var selectedMonth = Date()
    @State private var showMonthPicker = false

    // Computed data for selected month
    private var monthData: MonthData {
        let calendar = Calendar.current
        let transactions = repository.fetchAll()
        let monthTx = transactions.filter {
            $0.currency == settings.displayCurrency &&
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }

        let income = monthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = monthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let profit = income - expense

        // Previous month for comparison
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        let prevMonthTx = transactions.filter {
            $0.currency == settings.displayCurrency &&
            calendar.isDate($0.date, equalTo: previousMonth, toGranularity: .month)
        }
        let prevIncome = prevMonthTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let prevExpense = prevMonthTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let prevProfit = prevIncome - prevExpense

        // Category breakdown by profit contribution
        var categoryProfits: [String: Double] = [:]
        let incomeByCategory = Dictionary(grouping: monthTx.filter { $0.type == .income }) { $0.category }
        let expenseByCategory = Dictionary(grouping: monthTx.filter { $0.type == .expense }) { $0.category }

        // Calculate profit per category
        let allCategories = Set(incomeByCategory.keys).union(Set(expenseByCategory.keys))
        for category in allCategories {
            let categoryIncome = incomeByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
            let categoryExpense = expenseByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
            categoryProfits[category] = categoryIncome - categoryExpense
        }

        let categoryBreakdown = categoryProfits.map { category, profit in
            CategoryProfit(
                category: TransactionCategory.localizedName(for: category),
                amount: profit,
                percentage: profit / max(abs(profit), 1) * 100 // Percentage of total profit
            )
        }.sorted { $0.amount > $1.amount }

        return MonthData(
            income: income,
            expense: expense,
            profit: profit,
            previousProfit: prevProfit,
            hasPreviousData: !prevMonthTx.isEmpty,
            categoryBreakdown: categoryBreakdown
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // Header
                header

                // Month selector
                monthSelector

                if monthData.income > 0 || monthData.expense > 0 {
                    // Green summary card
                    profitSummaryCard

                    // Income/Expense/Profit rows
                    summaryRowsCard

                    // Category analysis
                    categoryAnalysisCard
                } else {
                    // Empty state
                    emptyStateCard
                }
            }
            .padding(Theme.Spacing.m)
            .padding(.bottom, 60)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text("ការវិភាគប្រាក់ចំណេញ")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.primaryText)

            Spacer()

            // Invisible spacer for center alignment
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, Theme.Spacing.s)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Text("សរុបប្រចាំខែ")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.primaryText)

            Spacer()

            Menu {
                ForEach(generateMonthOptions(), id: \.self) { date in
                    Button(action: { selectedMonth = date }) {
                        Text(formatMonthYear(date))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(formatMonthYear(selectedMonth))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.primaryText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.cardBackground)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Profit Summary Card

    private var profitSummaryCard: some View {
        let data = monthData
        let changePercentage = data.hasPreviousData && data.previousProfit != 0
            ? ((data.profit - data.previousProfit) / abs(data.previousProfit)) * 100
            : 0
        let isIncrease = changePercentage >= 0

        return HStack(spacing: Theme.Spacing.m) {
            // Icon badge
            Image(systemName: "leaf.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())

            // Profit label and amount
            VStack(alignment: .leading, spacing: 4) {
                Text("ប្រាក់ចំណេញសុទ្ធ")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                Text(CurrencyFormatter.string(data.profit, currency: settings.displayCurrency))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Percentage badge (if previous month has data)
            if data.hasPreviousData {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%.0f%%", abs(changePercentage)))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isIncrease ? Color.white.opacity(0.25) : Color.red.opacity(0.4))
                    .cornerRadius(12)

                    Text("ប្រៀបធៀបខែមុន")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.13, green: 0.55, blue: 0.13),
                    Color(red: 0.10, green: 0.45, blue: 0.10)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }

    // MARK: - Summary Rows Card

    private var summaryRowsCard: some View {
        let data = monthData

        return VStack(spacing: 0) {
            summaryRow(
                icon: "arrow.up.circle.fill",
                iconColor: .green,
                label: "សរុបចំណូល",
                amount: data.income
            )

            Divider()
                .padding(.leading, 60)

            summaryRow(
                icon: "arrow.down.circle.fill",
                iconColor: .red,
                label: "សរុបចំណាយ",
                amount: data.expense
            )

            Divider()
                .padding(.leading, 60)

            summaryRow(
                icon: "leaf.circle.fill",
                iconColor: data.profit >= 0 ? .green : .red,
                label: "ប្រាក់ចំណេញ",
                amount: data.profit
            )
        }
        .padding(.vertical, 8)
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }

    private func summaryRow(icon: String, iconColor: Color, label: String, amount: Double) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.primaryText)

            Spacer()

            Text(CurrencyFormatter.string(amount, currency: settings.displayCurrency))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText)
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, 12)
    }

    // MARK: - Category Analysis Card

    private var categoryAnalysisCard: some View {
        let topCategories = Array(monthData.categoryBreakdown.prefix(5))

        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("ការវិភាគប្រាក់ចំណេញតាមប្រភេទ")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.primaryText)

            if !topCategories.isEmpty {
                VStack(spacing: Theme.Spacing.m) {
                    ForEach(Array(topCategories.enumerated()), id: \.element.category) { index, category in
                        categoryRow(category: category, color: categoryColor(for: index))
                    }
                }
                .padding(Theme.Spacing.m)
                .background(Theme.cardBackground)
                .cornerRadius(12)
            } else {
                Text("មិនមានទិន្នន័យប្រភេទ")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.l)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
            }
        }
    }

    private func categoryRow(category: CategoryProfit, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Icon
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                // Category name
                Text(category.category.isEmpty ? "-" : category.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.primaryText)

                Spacer()

                // Amount and percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.string(category.amount, currency: settings.displayCurrency))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                    Text("(\(String(format: "%.0f%%", abs(category.percentage))))")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.secondaryText)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(color)
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(abs(category.percentage) / 100))), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(Theme.secondaryText.opacity(0.5))

            Text("មិនមានទិន្នន័យសម្រាប់ខែនេះ")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Helper Functions

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "km")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func generateMonthOptions() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []

        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                dates.append(date)
            }
        }

        return dates
    }

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.58, green: 0.40, blue: 0.74), // Purple
            Color(red: 0.20, green: 0.60, blue: 0.86), // Blue
            Color(red: 0.35, green: 0.71, blue: 0.40), // Green
            Color(red: 0.98, green: 0.74, blue: 0.20), // Orange
            Color(red: 0.93, green: 0.49, blue: 0.68)  // Pink
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Data Models

struct MonthData {
    let income: Double
    let expense: Double
    let profit: Double
    let previousProfit: Double
    let hasPreviousData: Bool
    let categoryBreakdown: [CategoryProfit]
}

struct CategoryProfit {
    let category: String
    let amount: Double
    let percentage: Double
}

// MARK: - Preview

struct ProfitAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let env = AppEnvironment(persistence: .preview)
        ProfitAnalysisView(repository: env.transactionRepository)
            .environmentObject(AppSettings.shared)
    }
}
