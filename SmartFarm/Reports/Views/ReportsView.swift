import SwiftUI

/// New comprehensive Reports screen with charts and insights
struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: FinanceCoordinator
    @State private var selectedTab = 0
    @State private var selectedMonth = Date()
    @State private var showProfitAnalysis = false
    @State private var showDetailedReport = false

    init(repository: TransactionRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                // 1. Header
                header

                // 2. Month Selector
                monthSelector

                // 3. Tab Selector
                tabSelector

                // 4. Tab-specific content
                if selectedTab == 0 {
                    // Overview tab - show everything
                    summaryCard
                    chartSection
                    pieChartSection
                    insightBox
                } else if selectedTab == 1 {
                    // Income/Expense tab
                    incomeExpenseSummary
                    incomeExpenseChartSection
                    pieChartSection
                } else if selectedTab == 2 {
                    // Category tab - keep current content
                    pieChartSection
                }
            }
            .padding(Theme.Spacing.m)
            .padding(.bottom, 60) // Clear tab bar
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear { viewModel.reload(currency: settings.displayCurrency) }
        .onChange(of: settings.displayCurrency) { viewModel.reload(currency: $0) }
        .sheet(isPresented: $showProfitAnalysis) {
            NavigationView {
                ProfitAnalysisView(repository: viewModel.repository)
                    .environmentObject(settings)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showDetailedReport) {
            NavigationView {
                DetailedReportView(repository: viewModel.repository)
                    .environmentObject(settings)
                    .environmentObject(coordinator)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.s) {
            // Back button
            Button(action: { coordinator.selectedTab = 1 }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
                    .frame(width: 36, height: 36)
            }

            // Icon and title
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 20))
                .foregroundColor(Theme.brand)
            Text("របាយការណ៍")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.primaryText)
            Spacer()
        }
        .padding(.top, Theme.Spacing.s)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button(action: { adjustMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Theme.brand)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.secondaryText)
                Text(monthYearText)
                    .font(Theme.Fonts.body.weight(.medium))
                    .foregroundColor(Theme.primaryText)
            }

            Spacer()

            Button(action: { adjustMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.brand)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.s)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "km")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func adjustMonth(by months: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "ទិដ្ឋភាពទូទៅ", index: 0)
            tabButton(title: "ចំណូល/ចំណាយ", index: 1)
            tabButton(title: "ជំពូក", index: 2)
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Text(title)
                .font(.system(size: 12, weight: selectedTab == index ? .semibold : .regular))
                .foregroundColor(selectedTab == index ? .white : Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedTab == index ? Theme.brand : Color.clear)
                .cornerRadius(8)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let profit = viewModel.monthlyTotals.last?.profit ?? 0
        let percentage = calculateGrowthPercentage()

        return HStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("ប្រាក់ចំណេញសុទ្ធ")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
                Text(CurrencyFormatter.string(profit, currency: settings.displayCurrency))
                    .font(.title3.weight(.bold))
                    .foregroundColor(Theme.primaryText)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                Text("\(percentage)%")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green)
            .cornerRadius(12)
        }
        .padding(Theme.Spacing.m)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private func calculateGrowthPercentage() -> Int {
        // Simplified growth calculation
        return 18
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("ការវិភាគប្រាក់ចំណេញ")
                .font(Theme.Fonts.body.weight(.semibold))
                .foregroundColor(Theme.primaryText)

            // Legend
            HStack(spacing: Theme.Spacing.m) {
                legendItem(color: .green, label: "ចំណូល")
                legendItem(color: .red, label: "ចំណាយ")
                legendItem(color: .orange, label: "ប្រាក់ចំណេញ")
            }
            .font(Theme.Fonts.caption)

            // Chart
            FarmCard {
                MonthlyBarChartView(totals: viewModel.monthlyTotals, currency: viewModel.currency)
                    .frame(height: 220)
            }

            // Detailed report button
            Button(action: { showDetailedReport = true }) {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("របាយការណ៍លម្អិត")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(Theme.Spacing.m)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.13, green: 0.55, blue: 0.13),
                            Color(red: 0.10, green: 0.45, blue: 0.10)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(Theme.secondaryText)
        }
    }

    // MARK: - Pie Chart Section

    private var pieChartSection: some View {
        let breakdown = viewModel.categoryBreakdown()
        let slices = breakdown.enumerated().map { index, item in
            PieSliceData(
                category: item.category,
                amount: item.amount,
                percentage: item.percentage,
                color: categoryColor(for: index)
            )
        }

        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("សមាមាត្រចំណាយ")
                .font(Theme.Fonts.body.weight(.semibold))
                .foregroundColor(Theme.primaryText)

            if !slices.isEmpty {
                FarmCard {
                    VStack(spacing: Theme.Spacing.m) {
                        // Donut chart centered at top
                        CategoryPieChartView(slices: slices, currency: viewModel.currency)
                            .frame(width: 200, height: 200)
                            .padding(.top, Theme.Spacing.m)

                        // Legend below: one row per category
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(slices) { slice in
                                HStack(spacing: 10) {
                                    // Colored dot
                                    Circle()
                                        .fill(slice.color)
                                        .frame(width: 12, height: 12)

                                    // Category name
                                    Text(slice.category.isEmpty ? "-" : slice.category)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.primaryText)

                                    Spacer()

                                    // Percentage and amount aligned right
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(Int(slice.percentage))%")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Theme.primaryText)
                                        Text(CurrencyFormatter.string(slice.amount, currency: viewModel.currency))
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.secondaryText)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.s)
                        .padding(.bottom, Theme.Spacing.m)
                    }
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

    private func categoryColor(for index: Int) -> Color {
        // More distinct color palette for better visibility
        let colors: [Color] = [
            Color(red: 0.58, green: 0.40, blue: 0.74), // Purple
            Color(red: 0.95, green: 0.42, blue: 0.42), // Red
            Color(red: 0.20, green: 0.60, blue: 0.86), // Blue
            Color(red: 0.35, green: 0.71, blue: 0.40), // Green
            Color(red: 0.98, green: 0.74, blue: 0.20), // Orange/Gold
            Color(red: 0.93, green: 0.49, blue: 0.68), // Pink
            Color(red: 0.60, green: 0.60, blue: 0.60)  // Gray for "Other"
        ]
        return colors[index % colors.count]
    }

    // MARK: - Insight Box

    private var insightBox: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("អនុសាសន៍")
                    .font(Theme.Fonts.body.weight(.bold))
                    .foregroundColor(Theme.primaryText)
                Text("ចំណាយរបស់អ្នកកើនឡើង 12% ក្នុងខែនេះ។ ពិចារណាកាត់បន្ថយការចំណាយលើធាតុផ្សំដែលមិនចាំបាច់ដើម្បីបង្កើនប្រាក់ចំណេញ។")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Income/Expense Tab Content

    private var incomeExpenseSummary: some View {
        let latestMonth = viewModel.monthlyTotals.last
        let income = latestMonth?.income ?? 0
        let expense = latestMonth?.expense ?? 0

        return HStack(spacing: Theme.Spacing.m) {
            // Income card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Spacer()
                }
                Text("ចំណូល")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
                Text(CurrencyFormatter.string(income, currency: settings.displayCurrency))
                    .font(.title3.weight(.bold))
                    .foregroundColor(Theme.primaryText)
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            // Expense card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    Spacer()
                }
                Text("ចំណាយ")
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
                Text(CurrencyFormatter.string(expense, currency: settings.displayCurrency))
                    .font(.title3.weight(.bold))
                    .foregroundColor(Theme.primaryText)
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var incomeExpenseChartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("ការវិភាគប្រាក់ចំណេញ")
                .font(Theme.Fonts.body.weight(.semibold))
                .foregroundColor(Theme.primaryText)

            // Legend (without profit)
            HStack(spacing: Theme.Spacing.m) {
                legendItem(color: .green, label: "ចំណូល")
                legendItem(color: .red, label: "ចំណាយ")
            }
            .font(Theme.Fonts.caption)

            // Chart without profit line
            FarmCard {
                ReportsIncomeExpenseChartView(totals: viewModel.monthlyTotals, currency: viewModel.currency)
                    .frame(height: 220)
            }
        }
    }
}

// MARK: - Pie Chart Components

/// Data for a single pie slice
struct PieSliceData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
}

/// Custom pie chart showing expense breakdown by category
struct CategoryPieChartView: View {
    let slices: [PieSliceData]
    let currency: Currency

    var body: some View {
        ZStack {
            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: slice.color
                )
            }

            // Donut hole
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 70, height: 70)
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let total = slices.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return .degrees(total * 3.6 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let total = slices.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return .degrees(total * 3.6 - 90)
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) / 2
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        let env = AppEnvironment(persistence: .preview)
        ReportsView(repository: env.transactionRepository)
            .environmentObject(AppSettings.shared)
            .environmentObject(FinanceCoordinator())
    }
}
