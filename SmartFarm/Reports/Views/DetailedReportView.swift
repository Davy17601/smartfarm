import SwiftUI

/// Comprehensive detailed report screen with multiple time periods and daily breakdowns
struct DetailedReportView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var settings: AppSettings
    let repository: TransactionRepositoryProtocol

    @State private var selectedPeriod: TimePeriod = .thirtyDays
    @State private var selectedChartType: ChartType = .income

    // Computed data for selected period
    private var periodData: PeriodData {
        let calendar = Calendar.current
        let now = Date()
        let transactions = repository.fetchAll()

        // Calculate date range for selected period
        let periodStart: Date
        switch selectedPeriod {
        case .sevenDays:
            periodStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .thirtyDays:
            periodStart = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .threeMonths:
            periodStart = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .oneYear:
            periodStart = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        // Filter transactions for current period
        let periodTx = transactions.filter {
            $0.currency == settings.displayCurrency &&
            $0.date >= periodStart && $0.date <= now
        }

        // Calculate totals for current period
        let income = periodTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = periodTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let profit = income - expense

        // Calculate previous period for comparison
        let previousStart: Date
        let previousEnd = periodStart
        switch selectedPeriod {
        case .sevenDays:
            previousStart = calendar.date(byAdding: .day, value: -7, to: periodStart) ?? periodStart
        case .thirtyDays:
            previousStart = calendar.date(byAdding: .day, value: -30, to: periodStart) ?? periodStart
        case .threeMonths:
            previousStart = calendar.date(byAdding: .month, value: -3, to: periodStart) ?? periodStart
        case .oneYear:
            previousStart = calendar.date(byAdding: .year, value: -1, to: periodStart) ?? periodStart
        }

        let previousTx = transactions.filter {
            $0.currency == settings.displayCurrency &&
            $0.date >= previousStart && $0.date < previousEnd
        }

        let prevIncome = previousTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let prevExpense = previousTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let prevProfit = prevIncome - prevExpense

        // Category breakdown for donut chart
        let expenses = periodTx.filter { $0.type == .expense }
        let total = expenses.reduce(0.0) { $0 + $1.amount }

        var categoryTotals: [String: Double] = [:]
        for tx in expenses {
            let localizedName = TransactionCategory.localizedName(for: tx.category)
            categoryTotals[localizedName, default: 0] += tx.amount
        }

        let allCategories = categoryTotals.map { category, amount in
            CategoryBreakdown(
                category: category,
                amount: amount,
                percentage: total > 0 ? (amount / total) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }

        // Limit to top 5, group rest as "ផ្សេងៗ"
        let topCategories: [CategoryBreakdown]
        if allCategories.count <= 5 {
            topCategories = allCategories
        } else {
            let top5 = Array(allCategories.prefix(5))
            let others = Array(allCategories.dropFirst(5))
            let otherTotal = others.reduce(0.0) { $0 + $1.amount }
            let otherPercentage = total > 0 ? (otherTotal / total) * 100 : 0

            if otherTotal > 0 {
                topCategories = top5 + [CategoryBreakdown(
                    category: "ផ្សេងៗ",
                    amount: otherTotal,
                    percentage: otherPercentage
                )]
            } else {
                topCategories = top5
            }
        }

        // Chart buckets - grouped by period
        let chartBuckets = computeChartBuckets(transactions: periodTx, start: periodStart, end: now, period: selectedPeriod)

        // Daily breakdown
        let dailyBreakdown = computeDailyBreakdown(transactions: periodTx, start: periodStart, end: now)

        // Category profit breakdown (for reusing ProfitAnalysisView component)
        var categoryProfits: [String: Double] = [:]
        let incomeByCategory = Dictionary(grouping: periodTx.filter { $0.type == .income }) { $0.category }
        let expenseByCategory = Dictionary(grouping: periodTx.filter { $0.type == .expense }) { $0.category }

        let allProfitCategories = Set(incomeByCategory.keys).union(Set(expenseByCategory.keys))
        for category in allProfitCategories {
            let categoryIncome = incomeByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
            let categoryExpense = expenseByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
            categoryProfits[category] = categoryIncome - categoryExpense
        }

        let categoryProfitBreakdown = categoryProfits.map { category, profit in
            CategoryProfit(
                category: TransactionCategory.localizedName(for: category),
                amount: profit,
                percentage: profit / max(abs(profit), 1) * 100
            )
        }.sorted { $0.amount > $1.amount }

        return PeriodData(
            periodStart: periodStart,
            periodEnd: now,
            income: income,
            expense: expense,
            profit: profit,
            previousIncome: prevIncome,
            previousExpense: prevExpense,
            previousProfit: prevProfit,
            hasPreviousData: !previousTx.isEmpty,
            categoryBreakdown: topCategories,
            chartBuckets: chartBuckets,
            dailyBreakdown: dailyBreakdown,
            categoryProfitBreakdown: categoryProfitBreakdown,
            allTransactions: periodTx
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // 1. Header
                header

                // 2. Period Selector
                periodSelector

                // 3. Date Range Card
                dateRangeCard

                // 4. Three Summary Cards
                summaryCards

                // 5. Donut Chart - សង្ខេបតាមប្រភេទ
                donutChartSection

                // 6. Bar Chart with Segmented Control
                barChartSection

                // 7. Daily Report Section
                dailyReportSection

                // 8. Category Analysis (reused from ProfitAnalysisView)
                categoryAnalysisSection
            }
            .padding(Theme.Spacing.m)
            .padding(.bottom, 60)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.s) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                    .frame(width: 36, height: 36)
            }

            Text("របាយការណ៍លម្អិត")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.primaryText)

            Spacer()
        }
        .padding(.top, Theme.Spacing.s)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                periodButton(period: period)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func periodButton(period: TimePeriod) -> some View {
        Button(action: { selectedPeriod = period }) {
            Text(period.displayName)
                .font(.system(size: 12, weight: selectedPeriod == period ? .semibold : .regular))
                .foregroundColor(selectedPeriod == period ? .white : Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedPeriod == period ? Color(red: 0.12, green: 0.48, blue: 0.20) : Color.clear)
                .cornerRadius(8)
        }
    }

    // MARK: - Date Range Card

    private var dateRangeCard: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundColor(Theme.brand)

            Text(formatDateRange())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.primaryText)

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 12))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(Theme.Spacing.m)
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "km")
        formatter.dateFormat = "d MMMM yyyy"

        let data = periodData
        let startStr = formatter.string(from: data.periodStart)
        let endStr = formatter.string(from: data.periodEnd)

        return "ចាប់ពី \(startStr) - \(endStr)"
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let data = periodData

        return HStack(spacing: Theme.Spacing.s) {
            summaryCard(
                title: "ចំណូល",
                amount: data.income,
                backgroundColor: Color(red: 0.18, green: 0.62, blue: 0.27),
                cardType: .income,
                change: data.hasPreviousData ? calculatePercentageChange(current: data.income, previous: data.previousIncome, type: .income) : nil
            )

            summaryCard(
                title: "ចំណាយ",
                amount: data.expense,
                backgroundColor: Color(red: 0.85, green: 0.23, blue: 0.23),
                cardType: .expense,
                change: data.hasPreviousData ? calculatePercentageChange(current: data.expense, previous: data.previousExpense, type: .expense) : nil
            )

            summaryCard(
                title: "ប្រាក់ចំណេញ",
                amount: data.profit,
                backgroundColor: data.profit >= 0 ? Color(red: 0.19, green: 0.44, blue: 0.84) : Color(red: 0.85, green: 0.23, blue: 0.23),
                cardType: .profit,
                change: data.hasPreviousData ? calculatePercentageChange(current: data.profit, previous: data.previousProfit, type: .profit) : nil
            )
        }
    }

    private func summaryCard(title: String, amount: Double, backgroundColor: Color, cardType: CardType, change: PercentageChange?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Text(CurrencyFormatter.string(amount, currency: settings.displayCurrency))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let change = change {
                HStack(spacing: 2) {
                    Image(systemName: change.isIncrease ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(Int(abs(change.percentage)))%")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.3))
                .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.s)
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private func calculatePercentageChange(current: Double, previous: Double, type: CardType) -> PercentageChange? {
        guard previous != 0 else { return nil }
        let percentage = ((current - previous) / abs(previous)) * 100

        // Determine if increase is "good" based on card type
        let isIncrease: Bool
        switch type {
        case .income, .profit:
            // For income and profit: up is good (green), down is bad (red)
            isIncrease = percentage >= 0
        case .expense:
            // For expense: up is bad (red), down is good (green)
            isIncrease = percentage < 0
        }

        return PercentageChange(percentage: percentage, isIncrease: isIncrease)
    }

    // MARK: - Donut Chart Section

    private var donutChartSection: some View {
        let breakdown = periodData.categoryBreakdown
        let slices = breakdown.enumerated().map { index, item in
            PieSliceData(
                category: item.category,
                amount: item.amount,
                percentage: item.percentage,
                color: categoryColor(for: index)
            )
        }

        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("សង្ខេបតាមប្រភេទ")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.primaryText)

            if !slices.isEmpty {
                FarmCard {
                    HStack(alignment: .top, spacing: Theme.Spacing.m) {
                        // Donut chart on the left
                        ZStack {
                            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                                PieSlice(
                                    startAngle: startAngle(for: index, slices: slices),
                                    endAngle: endAngle(for: index, slices: slices),
                                    color: slice.color
                                )
                            }

                            // Donut hole with total
                            VStack(spacing: 2) {
                                Text(CurrencyFormatter.string(periodData.expense, currency: settings.displayCurrency))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.primaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .frame(width: 70, height: 70)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                        }
                        .frame(width: 140, height: 140)

                        // Legend on the right
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(slices) { slice in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(slice.color)
                                        .frame(width: 10, height: 10)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(slice.category.isEmpty ? "-" : slice.category)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Theme.primaryText)
                                            .lineLimit(1)
                                        Text("\(Int(slice.percentage))%")
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.secondaryText)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(Theme.Spacing.m)
                }
            } else {
                FarmCard {
                    Text("មិនមានទិន្នន័យ")
                        .foregroundColor(Theme.secondaryText)
                        .padding(Theme.Spacing.m)
                }
            }
        }
    }

    private func startAngle(for index: Int, slices: [PieSliceData]) -> Angle {
        let total = slices.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return .degrees(total * 3.6 - 90)
    }

    private func endAngle(for index: Int, slices: [PieSliceData]) -> Angle {
        let total = slices.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return .degrees(total * 3.6 - 90)
    }

    // MARK: - Bar Chart Section

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("ក្រាហ្វិកប្រាក់ចំណូល-ចំណាយ")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.primaryText)

            // Segmented control
            HStack(spacing: 0) {
                chartTypeButton(type: .income)
                chartTypeButton(type: .expense)
                chartTypeButton(type: .profit)
            }
            .padding(4)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Bar chart
            FarmCard {
                VStack(spacing: Theme.Spacing.s) {
                    DetailedBarChartView(
                        buckets: periodData.chartBuckets,
                        chartType: selectedChartType,
                        currency: settings.displayCurrency,
                        period: selectedPeriod
                    )
                    .frame(height: 180)
                    .padding(Theme.Spacing.s)

                    // Top categories summary
                    topCategoriesSummary
                }
            }
        }
    }

    private func chartTypeButton(type: ChartType) -> some View {
        Button(action: { selectedChartType = type }) {
            Text(type.displayName)
                .font(.system(size: 12, weight: selectedChartType == type ? .semibold : .regular))
                .foregroundColor(selectedChartType == type ? .white : Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedChartType == type ? Color(red: 0.12, green: 0.48, blue: 0.20) : Color.clear)
                .cornerRadius(8)
        }
    }

    private var topCategoriesSummary: some View {
        let transactions = periodData.allTransactions
        var categoryTotals: [String: Double] = [:]

        // Compute top categories based on selected chart type
        switch selectedChartType {
        case .income:
            let incomeTx = transactions.filter { $0.type == .income }
            for tx in incomeTx {
                let name = TransactionCategory.localizedName(for: tx.category)
                categoryTotals[name, default: 0] += tx.amount
            }
        case .expense:
            let expenseTx = transactions.filter { $0.type == .expense }
            for tx in expenseTx {
                let name = TransactionCategory.localizedName(for: tx.category)
                categoryTotals[name, default: 0] += tx.amount
            }
        case .profit:
            // For profit, show top profit category and top expense category
            var profitByCategory: [String: Double] = [:]
            let incomeByCategory = Dictionary(grouping: transactions.filter { $0.type == .income }) { $0.category }
            let expenseByCategory = Dictionary(grouping: transactions.filter { $0.type == .expense }) { $0.category }

            let allCategories = Set(incomeByCategory.keys).union(Set(expenseByCategory.keys))
            for category in allCategories {
                let income = incomeByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
                let expense = expenseByCategory[category]?.reduce(0) { $0 + $1.amount } ?? 0
                let name = TransactionCategory.localizedName(for: category)
                profitByCategory[name] = income - expense
            }
            categoryTotals = profitByCategory
        }

        let topCategories = categoryTotals.sorted { $0.value > $1.value }.prefix(3)

        return VStack(spacing: 6) {
            ForEach(Array(topCategories), id: \.key) { category, amount in
                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryColorForName(category))
                        .frame(width: 8, height: 8)

                    Text(category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.primaryText)

                    Spacer()

                    Text(CurrencyFormatter.string(amount, currency: settings.displayCurrency))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
    }

    private func categoryColorForName(_ name: String) -> Color {
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            Color(red: 0.58, green: 0.40, blue: 0.74),
            Color(red: 0.95, green: 0.42, blue: 0.42),
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.35, green: 0.71, blue: 0.40),
            Color(red: 0.98, green: 0.74, blue: 0.20),
            Color(red: 0.93, green: 0.49, blue: 0.68)
        ]
        return colors[hash % colors.count]
    }

    // MARK: - Daily Report Section

    private var dailyReportSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("របាយការណ៍ប្រចាំថ្ងៃ")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.primaryText)

            let dailyGroups = periodData.dailyBreakdown.filter { $0.hasTransactions }

            if dailyGroups.isEmpty {
                FarmCard {
                    VStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.secondaryText.opacity(0.5))
                        Text("មិនមានទិន្នន័យសម្រាប់រយៈពេលនេះ")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.l)
                }
            } else {
                ForEach(dailyGroups) { daily in
                    dailyCard(daily: daily)
                }
            }
        }
    }

    private func dailyCard(daily: DailyBreakdown) -> some View {
        FarmCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                // Date header
                Text(formatDayDate(daily.date))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.primaryText)

                // Three figures in a row
                HStack(spacing: Theme.Spacing.s) {
                    dailySummaryItem(
                        label: "ចំណូល",
                        amount: daily.income,
                        color: .green
                    )
                    dailySummaryItem(
                        label: "ចំណាយ",
                        amount: daily.expense,
                        color: .red
                    )
                    dailySummaryItem(
                        label: "ប្រាក់ចំណេញ",
                        amount: daily.profit,
                        color: daily.profit >= 0 ? .green : .red
                    )
                }

                // Transaction list
                if !daily.transactions.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(spacing: 8) {
                        ForEach(daily.transactions) { tx in
                            transactionRow(tx: tx)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.m)
        }
    }

    private func dailySummaryItem(label: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.secondaryText)
            Text(CurrencyFormatter.string(amount, currency: settings.displayCurrency))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private func transactionRow(tx: Transaction) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(TransactionCategory.localizedName(for: tx.category))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.primaryText)
                if !tx.note.isEmpty {
                    Text(tx.note)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("\(tx.type == .income ? "+" : "-")\(CurrencyFormatter.string(tx.amount, currency: tx.currency))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tx.type == .income ? .green : .red)
        }
    }

    private func formatDayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "km")
        formatter.dateFormat = "ថ្ងៃទី d MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Category Analysis Section (reused from ProfitAnalysisView)

    private var categoryAnalysisSection: some View {
        let topCategories = Array(periodData.categoryProfitBreakdown.prefix(5))

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
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                Text(category.category.isEmpty ? "-" : category.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.primaryText)

                Spacer()

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

    // MARK: - Helper Functions

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.58, green: 0.40, blue: 0.74), // Purple
            Color(red: 0.95, green: 0.42, blue: 0.42), // Red
            Color(red: 0.20, green: 0.60, blue: 0.86), // Blue
            Color(red: 0.35, green: 0.71, blue: 0.40), // Green
            Color(red: 0.98, green: 0.74, blue: 0.20), // Orange/Gold
            Color(red: 0.93, green: 0.49, blue: 0.68)  // Pink
        ]
        return colors[index % colors.count]
    }

    private func computeDailyBreakdown(transactions: [Transaction], start: Date, end: Date) -> [DailyBreakdown] {
        let calendar = Calendar.current
        var dailyMap: [Date: [Transaction]] = [:]

        // Group transactions by day
        for tx in transactions {
            let dayStart = calendar.startOfDay(for: tx.date)
            dailyMap[dayStart, default: []].append(tx)
        }

        // Create daily breakdown sorted by date (newest first)
        return dailyMap.map { date, txs in
            let income = txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return DailyBreakdown(
                date: date,
                income: income,
                expense: expense,
                profit: income - expense,
                transactions: txs.sorted { $0.date > $1.date }
            )
        }.sorted { $0.date > $1.date }
    }

    private func computeChartBuckets(transactions: [Transaction], start: Date, end: Date, period: TimePeriod) -> [ChartBucket] {
        let calendar = Calendar.current
        var buckets: [ChartBucket] = []

        switch period {
        case .sevenDays:
            // Daily buckets (7 bars)
            for dayOffset in 0..<7 {
                guard let bucketDate = calendar.date(byAdding: .day, value: -dayOffset, to: end) else { continue }
                let dayStart = calendar.startOfDay(for: bucketDate)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

                let bucketTx = transactions.filter { $0.date >= dayStart && $0.date < dayEnd }
                let income = bucketTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = bucketTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "km")
                formatter.dateFormat = "d"
                let label = formatter.string(from: bucketDate)

                buckets.append(ChartBucket(
                    label: label,
                    income: income,
                    expense: expense,
                    profit: income - expense,
                    startDate: dayStart
                ))
            }

        case .thirtyDays:
            // Weekly buckets (~4-5 bars)
            var currentWeekStart = calendar.startOfDay(for: end)
            for _ in 0..<5 {
                guard let weekStart = calendar.date(byAdding: .day, value: -6, to: currentWeekStart) else { break }
                let weekEnd = currentWeekStart

                let bucketTx = transactions.filter { $0.date >= weekStart && $0.date <= weekEnd }
                let income = bucketTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = bucketTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "km")
                formatter.dateFormat = "d"
                let startLabel = formatter.string(from: weekStart)
                let endLabel = formatter.string(from: weekEnd)
                let label = "\(startLabel)-\(endLabel)"

                buckets.append(ChartBucket(
                    label: label,
                    income: income,
                    expense: expense,
                    profit: income - expense,
                    startDate: weekStart
                ))

                currentWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) ?? weekStart
            }

        case .threeMonths:
            // Monthly buckets (3 bars)
            for monthOffset in 0..<3 {
                guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: end) else { continue }
                guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { continue }

                let bucketTx = transactions.filter { $0.date >= monthInterval.start && $0.date < monthInterval.end }
                let income = bucketTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = bucketTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "km")
                formatter.dateFormat = "MMM"
                let label = formatter.string(from: monthDate)

                buckets.append(ChartBucket(
                    label: label,
                    income: income,
                    expense: expense,
                    profit: income - expense,
                    startDate: monthInterval.start
                ))
            }

        case .oneYear:
            // Monthly buckets (12 bars)
            for monthOffset in 0..<12 {
                guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: end) else { continue }
                guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { continue }

                let bucketTx = transactions.filter { $0.date >= monthInterval.start && $0.date < monthInterval.end }
                let income = bucketTx.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = bucketTx.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "km")
                formatter.dateFormat = "MMM"
                let label = formatter.string(from: monthDate)

                buckets.append(ChartBucket(
                    label: label,
                    income: income,
                    expense: expense,
                    profit: income - expense,
                    startDate: monthInterval.start
                ))
            }
        }

        return buckets.reversed()
    }
}

// MARK: - Data Models

enum TimePeriod: CaseIterable {
    case sevenDays
    case thirtyDays
    case threeMonths
    case oneYear

    var displayName: String {
        switch self {
        case .sevenDays: return "7 ថ្ងៃ"
        case .thirtyDays: return "30 ថ្ងៃ"
        case .threeMonths: return "3 ខែ"
        case .oneYear: return "1 ឆ្នាំ"
        }
    }
}

enum ChartType {
    case income
    case expense
    case profit

    var displayName: String {
        switch self {
        case .income: return "ចំណូល"
        case .expense: return "ចំណាយ"
        case .profit: return "ប្រាក់ចំណេញ"
        }
    }
}

enum CardType {
    case income
    case expense
    case profit
}

struct PeriodData {
    let periodStart: Date
    let periodEnd: Date
    let income: Double
    let expense: Double
    let profit: Double
    let previousIncome: Double
    let previousExpense: Double
    let previousProfit: Double
    let hasPreviousData: Bool
    let categoryBreakdown: [CategoryBreakdown]
    let chartBuckets: [ChartBucket]
    let dailyBreakdown: [DailyBreakdown]
    let categoryProfitBreakdown: [CategoryProfit]
    let allTransactions: [Transaction]
}

struct ChartBucket: Identifiable {
    let id = UUID()
    let label: String
    let income: Double
    let expense: Double
    let profit: Double
    let startDate: Date
}

struct DailyBreakdown: Identifiable {
    let id = UUID()
    let date: Date
    let income: Double
    let expense: Double
    let profit: Double
    let transactions: [Transaction]

    var hasTransactions: Bool {
        !transactions.isEmpty
    }
}

struct PercentageChange {
    let percentage: Double
    let isIncrease: Bool
}

// MARK: - Bar Chart Component

struct DetailedBarChartView: View {
    let buckets: [ChartBucket]
    let chartType: ChartType
    let currency: Currency
    let period: TimePeriod

    var body: some View {
        GeometryReader { geometry in
            let maxValue = getMaxValue()
            let barWidth: CGFloat = min(20, (geometry.size.width - CGFloat(buckets.count - 1) * 8) / CGFloat(buckets.count))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(buckets) { bucket in
                    let value = getValue(for: bucket)
                    let absValue = abs(value)
                    let barHeight = maxValue > 0 ? (absValue / maxValue) * 120 : 0

                    VStack(spacing: 4) {
                        // Value label above bar
                        Text(formatCompactValue(absValue))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .frame(height: 12)

                        // Bar
                        VStack(spacing: 0) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 3)
                                .fill(getColor(for: value))
                                .frame(width: barWidth, height: max(2, barHeight))
                        }
                        .frame(height: 120)

                        // Bucket label below bar
                        Text(bucket.label)
                            .font(.system(size: 9))
                            .foregroundColor(Theme.secondaryText)
                            .lineLimit(1)
                            .frame(height: 14)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func getValue(for bucket: ChartBucket) -> Double {
        switch chartType {
        case .income: return bucket.income
        case .expense: return bucket.expense
        case .profit: return bucket.profit
        }
    }

    private func getMaxValue() -> Double {
        let values = buckets.map { abs(getValue(for: $0)) }
        return values.max() ?? 1
    }

    private func getColor(for value: Double) -> Color {
        switch chartType {
        case .income: return Color(red: 0.18, green: 0.62, blue: 0.27)
        case .expense: return Color(red: 0.85, green: 0.23, blue: 0.23)
        case .profit: return value >= 0 ? Color(red: 0.19, green: 0.44, blue: 0.84) : Color(red: 0.85, green: 0.23, blue: 0.23)
        }
    }

    private func formatCompactValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else if value > 0 {
            return String(format: "%.0f", value)
        } else {
            return ""
        }
    }
}

// MARK: - Preview

struct DetailedReportView_Previews: PreviewProvider {
    static var previews: some View {
        let env = AppEnvironment(persistence: .preview)
        DetailedReportView(repository: env.transactionRepository)
            .environmentObject(AppSettings.shared)
            .environmentObject(FinanceCoordinator())
    }
}
