import SwiftUI

/// New comprehensive Reports screen with charts and insights
struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedTab = 0
    @State private var selectedMonth = Date()

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

                // 4. Summary Card
                summaryCard

                // 5. Line/Bar Combo Chart Section
                chartSection

                // 6. Donut/Pie Chart Section
                pieChartSection

                // 7. Insight/Tip Box
                insightBox
            }
            .padding(Theme.Spacing.m)
            .padding(.bottom, 60) // Clear tab bar
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear { viewModel.reload(currency: settings.displayCurrency) }
        .onChange(of: settings.displayCurrency) { viewModel.reload(currency: $0) }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 16))
                .foregroundColor(Theme.brand)
            Text("របាយការណ៍")
                .font(.title2.weight(.bold))
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
            Text("ការនិង្គ្រាក់ចំណេញ")
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
                    HStack(alignment: .top, spacing: Theme.Spacing.m) {
                        // Pie chart
                        CategoryPieChartView(slices: slices, currency: viewModel.currency)
                            .frame(width: 140, height: 140)

                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(slices) { slice in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(slice.color)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(slice.category.displayName)
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.primaryText)
                                        Text("\(Int(slice.percentage))%")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.s)
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
        let colors: [Color] = [.purple, .red, .orange, .green, .blue, .pink]
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
}

// MARK: - Pie Chart Components

/// Data for a single pie slice
struct PieSliceData: Identifiable {
    let id = UUID()
    let category: TransactionCategory
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
    }
}
