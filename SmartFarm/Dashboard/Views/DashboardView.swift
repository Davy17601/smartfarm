import SwiftUI

/// Home tab: a unified snapshot of the farm with navigation into each module.
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var coordinator: FinanceCoordinator
    @EnvironmentObject private var settings: AppSettings
    @Binding private var selectedTab: Int

    // Alert state
    @State private var showClearOldAlert = false
    @State private var showUndoLastAlert = false
    @State private var selectedTransactionToDelete: Transaction? = nil

    // Activity edit/delete state
    @State private var activityToEdit: FarmActivity? = nil
    @State private var activityToDelete: FarmActivity? = nil
    @State private var showEditActivitySheet = false

    // MARK: - Custom Dashboard Colors
    /// Darker, more saturated colors for better contrast
    private let dashboardGreen = Color(red: 0.1, green: 0.35, blue: 0.1)
    private let darkerRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let darkerBlue = Color(red: 0.1, green: 0.3, blue: 0.7)

    init(environment: AppEnvironment, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: environment.makeDashboardViewModel())
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Green header section (scrolls with content)
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            gradient: Gradient(colors: [dashboardGreen, dashboardGreen.opacity(0.85)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 250)
                        .clipShape(RoundedBottomRectangle(radius: 24))
                        .ignoresSafeArea(edges: .top)

                        greetingText
                            .padding(.bottom, 40)
                    }

                    // Overlapping cards section
                    VStack(spacing: Theme.Spacing.m) {
                        monthSummary
                        upcomingActivitiesSection
                        upcomingRemindersSection
                        latestTransactionsSection
                        transactionHistorySection
                        categoryPieChartSection
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.bottom, Theme.Spacing.m)
                    .offset(y: -75) // Pull cards up to overlap green area (tighter spacing)
                    .background(Theme.background)
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Greeting text

    private var greetingText: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(L("dashboard.greeting"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("តាមដានចំណូល ចំណាយ")
                    .font(Theme.Fonts.body.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                Text(todayDateString)
                    .font(Theme.Fonts.body)
                    .foregroundColor(.white.opacity(0.95))
            }
            Spacer()
            hamburgerMenu
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, Theme.Spacing.m)
        .padding(.bottom, 60) // Extra padding to accommodate overlapping cards
    }

    private var hamburgerMenu: some View {
        Menu {
            Button(action: { selectedTab = 1 }) {
                Label(L("tab.finance"), systemImage: "dollarsign.circle")
            }
            Button(action: { selectedTab = 2 }) {
                Label(L("tab.calendar"), systemImage: "calendar")
            }
            Button(action: { selectedTab = 3 }) {
                Label(L("tab.settings"), systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
    }

    private var todayDateString: String {
        LocalizedDate.longStringWithKhmerNumerals(Date())
    }


    // MARK: - Month summary

    private var monthSummary: some View {
        let currency = settings.displayCurrency
        let profit = viewModel.monthProfit(in: currency)
        return VStack(spacing: Theme.Spacing.s) {
            // Income & Expense side by side
            HStack(spacing: Theme.Spacing.s) {
                SummaryCardView(
                    title: L("finance.income"),
                    value: CurrencyFormatter.string(viewModel.monthIncome(in: currency), currency: currency),
                    systemImage: "arrow.down.circle.fill", tint: dashboardGreen
                )
                SummaryCardView(
                    title: L("finance.expense"),
                    value: CurrencyFormatter.string(viewModel.monthExpense(in: currency), currency: currency),
                    systemImage: "arrow.up.circle.fill", tint: darkerRed
                )
            }
            // Profit below
            SummaryCardView(
                title: L("dashboard.profit"),
                value: CurrencyFormatter.signedString(profit, currency: currency),
                systemImage: profit >= 0 ? "arrow.up.right" : "arrow.down.right",
                tint: profit >= 0 ? darkerBlue : darkerRed,
                centered: true
            )
        }
    }

    // MARK: - Upcoming activities

    private var upcomingActivitiesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(L("calendar.activities")) {
                Button(L("common.viewAll")) { selectedTab = 2 }
                    .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
            let activities = Array(viewModel.upcomingActivities().prefix(5))
            if activities.isEmpty {
                FarmCard {
                    Text(L("calendar.noActivities")).foregroundColor(Theme.secondaryText)
                }
            } else {
                FarmCard {
                    ForEach(activities) { activity in
                        activityRow(activity)
                        if activity.id != activities.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func activityRow(_ activity: FarmActivity) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "leaf.fill")
                .foregroundColor(dashboardGreen)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(Theme.Fonts.body)
                    .foregroundColor(Theme.primaryText)
                Text(LocalizedDate.dateTimeWithAMPM(activity.date))
                    .font(Theme.Fonts.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer()
            if let badge = viewModel.urgencyBadge(for: activity.date) {
                urgencyBadge(badge, for: activity.date)
            }
            Button(action: {
                activityToEdit = activity
                showEditActivitySheet = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(Theme.brand)
                    .frame(width: 20, height: 20)
            }
            Button(action: {
                activityToDelete = activity
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Upcoming reminders

    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(L("dashboard.upcomingReminders")) {
                Button(L("common.viewAll")) { selectedTab = 2 }
                    .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
            let reminders = Array(viewModel.upcomingReminders().prefix(5))
            if reminders.isEmpty {
                FarmCard {
                    Text(L("dashboard.noReminders")).foregroundColor(Theme.secondaryText)
                }
            } else {
                FarmCard {
                    ForEach(reminders) { reminder in
                        reminderRow(reminder)
                        if reminder.id != reminders.last?.id {
                            Divider()
                        }
                    }
                }
            }
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
