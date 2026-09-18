import SwiftUI

/// Home tab: a unified snapshot of the farm with navigation into each module.
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var coordinator: FinanceCoordinator
    @EnvironmentObject private var settings: AppSettings
    @Binding private var selectedTab: Int

    private let transactionRepository: TransactionRepositoryProtocol

    // Alert state
    @State private var showClearOldAlert = false
    @State private var showUndoLastAlert = false
    @State private var selectedTransactionToDelete: Transaction? = nil

    // Activity edit/delete state
    @State private var activityToEdit: FarmActivity? = nil
    @State private var activityToDelete: FarmActivity? = nil
    @State private var showEditActivitySheet = false

    // Quick Actions state
    @State private var showAddTransactionSheet = false


    // MARK: - Custom Dashboard Colors
    /// Darker, more saturated colors for better contrast
    private let dashboardGreen = Color(red: 0.1, green: 0.35, blue: 0.1)
    private let darkerRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let darkerBlue = Color(red: 0.1, green: 0.3, blue: 0.7)

    init(environment: AppEnvironment, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: environment.makeDashboardViewModel())
        _selectedTab = selectedTab
        self.transactionRepository = environment.transactionRepository
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top navigation bar
                    topNavigationBar
                        .background(Color.white)

                    // Header section with background image (scrolls with content)
                    ZStack(alignment: .bottom) {
                        ZStack {
                            // Background image
                            Image("dashboard_header_background")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 220)
                                .clipped()

                            // Dark overlay for text contrast
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.3)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .frame(height: 220)
                        .cornerRadius(16)

                        greetingText
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 12)

                    // Cards section - clean separation below background image
                    VStack(spacing: Theme.Spacing.s) {
                        monthSummary
                            .padding(.horizontal, 12)
                        quickActionsSection
                            .padding(.horizontal, 12)
                        latestTransactionsSection
                            .padding(.horizontal, Theme.Spacing.m)
                        transactionHistorySection
                            .padding(.horizontal, Theme.Spacing.m)
                        categoryPieChartSection
                            .padding(.horizontal, Theme.Spacing.m)
                    }
                    .padding(.top, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.m)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear { viewModel.reload() }
            .alert(isPresented: $showClearOldAlert) {
                Alert(
                    title: Text(L("dashboard.clearOldTitle")),
                    message: Text(L("dashboard.clearOldMessage")),
                    primaryButton: .destructive(Text(L("dashboard.clearOldConfirm"))) {
                        viewModel.clearOldTransactions()
                    },
                    secondaryButton: .cancel(Text(L("common.cancel")))
                )
            }
            .alert(isPresented: $showUndoLastAlert) {
                Alert(
                    title: Text(L("dashboard.undoLastTitle")),
                    message: Text(L("dashboard.undoLastMessage")),
                    primaryButton: .destructive(Text(L("dashboard.undoLastConfirm"))) {
                        viewModel.deleteLastTransaction()
                    },
                    secondaryButton: .cancel(Text(L("common.cancel")))
                )
            }
            .alert(item: $selectedTransactionToDelete) { transaction in
                Alert(
                    title: Text(L("dashboard.deleteTransactionTitle")),
                    message: Text(L("dashboard.deleteTransactionMessage")),
                    primaryButton: .destructive(Text(L("common.delete"))) {
                        viewModel.deleteTransaction(transaction)
                        selectedTransactionToDelete = nil
                    },
                    secondaryButton: .cancel {
                        selectedTransactionToDelete = nil
                    }
                )
            }
            .alert(item: $activityToDelete) { activity in
                Alert(
                    title: Text(L("dashboard.deleteActivityTitle")),
                    message: Text(L("dashboard.deleteActivityMessage")),
                    primaryButton: .destructive(Text(L("common.delete"))) {
                        viewModel.deleteActivity(activity)
                        activityToDelete = nil
                    },
                    secondaryButton: .cancel {
                        activityToDelete = nil
                    }
                )
            }
            .sheet(isPresented: $showEditActivitySheet) {
                if let activity = activityToEdit {
                    AddEditActivityView(mode: .edit(activity)) { updatedActivity in
                        viewModel.updateActivity(updatedActivity)
                        showEditActivitySheet = false
                        activityToEdit = nil
                    }
                }
            }
            .sheet(isPresented: $showAddTransactionSheet) {
                AddEditTransactionView(mode: .add) { _ in
                    showAddTransactionSheet = false
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left side: rice/farm icon + app name + tagline
            HStack(spacing: 8) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(dashboardGreen)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SmartFarm")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                    Text("តាមដាន | ចំណាយភ្លាមៗ | ព្រាក់ចំណេញប្រចាំខែ")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.secondaryText)
                }
            }

            Spacer()

            // Right side: bell icon with red dot + profile avatar
            HStack(spacing: 12) {
                // Bell icon with notification badge
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        // Handle notifications tap
                    }) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.secondaryText)
                    }

                    // Red dot badge
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -2)
                }
                .frame(width: 24, height: 24)

                // Profile avatar
                Button(action: {
                    // Handle profile tap
                    selectedTab = 3
                }) {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [dashboardGreen, Color.green.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Greeting text

    private var greetingText: some View {
        HStack(alignment: .top) {
            // Left side: Main greeting
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(L("dashboard.greeting"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("តាមដានចំណូល ចំណាយ")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Text(todayDateString)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.95))
            }

            Spacer()

            // Right side: Weather info
            weatherInfo
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 60)
    }

    private var weatherInfo: some View {
        VStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 28))
                .foregroundColor(.yellow)
            Text("32°C")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("ថ្ងៃត្រង់")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }

    private var todayDateString: String {
        LocalizedDate.longStringWithKhmerNumerals(Date())
    }


    // MARK: - Month summary

    private var monthSummary: some View {
        let currency = settings.displayCurrency
        let profit = viewModel.monthProfit(in: currency)
        return HStack(spacing: Theme.Spacing.s) {
            // Income card
            modernSummaryCard(
                iconName: "arrow.up",
                iconColor: dashboardGreen,
                title: "ចំណូលសរុប",
                value: CurrencyFormatter.string(viewModel.monthIncome(in: currency), currency: currency),
                valueColor: dashboardGreen,
                percentage: 12,
                isPositive: true
            )

            // Expense card
            modernSummaryCard(
                iconName: "arrow.down",
                iconColor: darkerRed,
                title: "ចំណាយសរុប",
                value: CurrencyFormatter.string(viewModel.monthExpense(in: currency), currency: currency),
                valueColor: darkerRed,
                percentage: 5,
                isPositive: false
            )

            // Profit card
            modernSummaryCard(
                iconName: "chart.bar.fill",
                iconColor: darkerBlue,
                title: "ព្រាក់ចំណេញ",
                value: CurrencyFormatter.signedString(profit, currency: currency),
                valueColor: darkerBlue,
                percentage: 18,
                isPositive: true
            )
        }
    }

    private func modernSummaryCard(iconName: String, iconColor: Color, title: String, value: String, valueColor: Color, percentage: Int, isPositive: Bool) -> some View {
        VStack(spacing: 12) {
            // Circular icon badge at top
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Title label
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)

            // Large amount value
            Text(value)
                .font(.system(size: 20, weight: .bold).monospacedDigit())
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Percentage badge at bottom
            percentageBadge(percentage: percentage, isPositive: isPositive, color: iconColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private func percentageBadge(percentage: Int, isPositive: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text("\(percentage)%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader("មុខងារហ័ស") { }

            // Single horizontal row of 4 quick action buttons
            HStack(spacing: Theme.Spacing.s) {
                quickActionButton(
                    title: "បញ្ចូលចំណូល",
                    icon: "plus.circle.fill",
                    color: .green,
                    backgroundColor: Color.green.opacity(0.15),
                    action: { showAddTransactionSheet = true }
                )
                quickActionButton(
                    title: "បញ្ចូលចំណាយ",
                    icon: "minus.circle.fill",
                    color: .red,
                    backgroundColor: Color.red.opacity(0.15),
                    action: { showAddTransactionSheet = true }
                )
                quickActionButton(
                    title: "របាយការណ៍",
                    icon: "chart.bar.fill",
                    color: .blue,
                    backgroundColor: Color.blue.opacity(0.15),
                    action: { selectedTab = 2 }
                )
                quickActionButton(
                    title: "ការកំណត់",
                    icon: "gearshape.fill",
                    color: .gray,
                    backgroundColor: Color.gray.opacity(0.15),
                    action: { selectedTab = 3 }
                )
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, backgroundColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "bell.fill")
                .foregroundColor(Theme.brand)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.primaryText)
                Text(LocalizedDate.dateTimeWithAMPM(reminder.dueDate))
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer()
            if let badge = viewModel.urgencyBadge(for: reminder.dueDate) {
                urgencyBadge(badge, for: reminder.dueDate)
            }
            Button(action: {
                // Action button - navigate to reminder details
                selectedTab = 2
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(Theme.secondaryText)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, 4)
    }

    /// Shared urgency badge: red for today, orange for tomorrow
    private func urgencyBadge(_ text: String, for date: Date) -> some View {
        let calendar = Calendar.current
        let badgeColor: Color = calendar.isDateInToday(date) ? .red : .orange

        return Text(text)
            .font(Theme.Fonts.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(8)
    }

    // MARK: - Latest transactions

    private var latestTransactionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(L("finance.recent"))
                    .font(Theme.Fonts.heading)
                    .foregroundColor(Theme.primaryText)
                Spacer()
                if !viewModel.latestTransactions.isEmpty {
                    Button(L("dashboard.undoLast")) {
                        showUndoLastAlert = true
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundColor(.orange)
                }
                Button(L("common.viewAll")) { selectedTab = 1 }
                    .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
            if viewModel.latestTransactions.isEmpty {
                FarmCard { Text(L("finance.empty")).foregroundColor(Theme.secondaryText) }
            } else {
                FarmCard {
                    ForEach(viewModel.latestTransactions) { transaction in
                        transactionRow(transaction, isCompact: true)
                        if transaction.id != viewModel.latestTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func transactionRow(_ transaction: Transaction, isCompact: Bool = false) -> some View {
        let tint = transaction.type == .income ? dashboardGreen : darkerRed
        return HStack(spacing: Theme.Spacing.s) {
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(transaction.title)
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.primaryText)
                    .lineLimit(1)
                Text(LocalizedDate.dayMonthString(transaction.date))
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer(minLength: Theme.Spacing.s)
            HStack(spacing: 4) {
                Text(CurrencyFormatter.string(transaction.amount, currency: transaction.currency))
                    .font(Theme.Fonts.body.monospacedDigit())
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .fixedSize()
                if isCompact {
                    Button(action: {
                        coordinator.navigate(to: transaction)
                        selectedTab = 1
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Theme.secondaryText)
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Transaction History Section

    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(L("dashboard.transactionHistory"))
                    .font(Theme.Fonts.heading)
                    .foregroundColor(Theme.primaryText)
                Spacer()
                Button(L("dashboard.clearOld")) {
                    showClearOldAlert = true
                }
                .font(Theme.Fonts.caption)
                .foregroundColor(.red)
            }
            if viewModel.allTransactions.isEmpty {
                FarmCard { Text(L("finance.empty")).foregroundColor(Theme.secondaryText) }
            } else {
                FarmCard {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.allTransactions) { transaction in
                                HStack(spacing: Theme.Spacing.s) {
                                    Circle()
                                        .fill(transaction.type == .income ? dashboardGreen : darkerRed)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(transaction.title)
                                            .font(Theme.Fonts.body)
                                            .foregroundColor(Theme.primaryText)
                                            .lineLimit(1)
                                        Text(LocalizedDate.dayMonthString(transaction.date))
                                            .font(Theme.Fonts.caption)
                                            .foregroundColor(Theme.secondaryText)
                                    }
                                    Spacer(minLength: Theme.Spacing.s)
                                    Text(CurrencyFormatter.string(transaction.amount, currency: transaction.currency))
                                        .font(Theme.Fonts.body.monospacedDigit())
                                        .foregroundColor(transaction.type == .income ? dashboardGreen : darkerRed)
                                        .lineLimit(1)
                                        .fixedSize()
                                    Button(action: {
                                        coordinator.navigate(to: transaction)
                                        selectedTab = 1
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(Theme.brand)
                                            .frame(width: 20, height: 20)
                                    }
                                    Button(action: {
                                        selectedTransactionToDelete = transaction
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding(.vertical, 2)
                                if transaction.id != viewModel.allTransactions.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }

    // MARK: - Category Pie Chart Section

    private var categoryPieChartSection: some View {
        let currency = settings.displayCurrency
        let breakdown = viewModel.categoryBreakdown(in: currency)
        let slices = breakdown.enumerated().map { index, item in
            DashboardPieSliceData(
                category: item.category,
                amount: item.amount,
                percentage: item.percentage,
                color: categoryColor(for: index)
            )
        }

        return VStack {
            if !slices.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    SectionHeader(L("reports.expenseByCategory")) {
                        Button(L("common.viewAll")) { selectedTab = 3 }
                            .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
                    }
                    FarmCard {
                        DashboardCategoryPieChartView(slices: slices, currency: currency)
                            .padding(.top, Theme.Spacing.s)
                    }
                }
            }
        }
    }

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .orange, .green, .purple, .pink, .yellow]
        return colors[index % colors.count]
    }
}

// MARK: - Dashboard Pie Chart Components

/// Data for a single pie slice on Dashboard
struct DashboardPieSliceData: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
    let color: Color
}

/// Custom pie chart showing expense breakdown by category on Dashboard
struct DashboardCategoryPieChartView: View {
    let slices: [DashboardPieSliceData]
    let currency: Currency

    private let size: CGFloat = 200

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            // Pie chart
            ZStack {
                ForEach(Array(slices.enumerated()), id: \.1.id) { index, slice in
                    DashboardPieSlice(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index)
                    )
                    .fill(slice.color)
                }
            }
            .frame(width: size, height: size)

            // Legend
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                ForEach(slices) { slice in
                    HStack(spacing: Theme.Spacing.s) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 12, height: 12)
                        Text(slice.category.displayName)
                            .font(Theme.Fonts.caption)
                            .foregroundColor(Theme.primaryText)
                        Spacer()
                        Text("\(Int(slice.percentage))%")
                            .font(Theme.Fonts.caption.weight(.medium))
                            .foregroundColor(Theme.secondaryText)
                        Text(CurrencyFormatter.string(slice.amount, currency: currency))
                            .font(Theme.Fonts.caption.monospacedDigit())
                            .foregroundColor(Theme.primaryText)
                    }
                }
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = slices.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: previousPercentages * 3.6 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let percentagesUpTo = slices.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: percentagesUpTo * 3.6 - 90)
    }
}

/// A single slice of the pie on Dashboard
struct DashboardPieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

/// Shape with rounded bottom corners only (for green header background)
struct RoundedBottomRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right edge down to corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))

        // Bottom-right rounded corner
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))

        // Bottom-left rounded corner
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )

        // Left edge back to top
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        return path
    }
}
