import SwiftUI

/// Home tab: a unified snapshot of the farm with navigation into each module.
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @EnvironmentObject private var coordinator: FinanceCoordinator
    @EnvironmentObject private var settings: AppSettings
    @Binding private var selectedTab: Int

    init(environment: AppEnvironment, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: environment.makeDashboardViewModel())
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.m) {
                    monthSummary
                    quickActions
                    latestTransactionsSection
                    upcomingSection
                }
                .padding(Theme.Spacing.m)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L("tab.dashboard"))
            .onAppear { viewModel.reload() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Month summary

    private var monthSummary: some View {
        let currency = settings.displayCurrency
        let profit = viewModel.monthProfit(in: currency)
        return VStack(spacing: Theme.Spacing.s) {
            SummaryCardView(
                title: L("finance.profitThisMonth"),
                value: CurrencyFormatter.signedString(profit, currency: currency),
                systemImage: "chart.line.uptrend.xyaxis",
                tint: profit >= 0 ? Theme.income : Theme.expense
            )
            HStack(spacing: Theme.Spacing.s) {
                SummaryCardView(
                    title: L("finance.income"),
                    value: CurrencyFormatter.string(viewModel.monthIncome(in: currency), currency: currency),
                    systemImage: "arrow.down.circle.fill", tint: Theme.income
                )
                SummaryCardView(
                    title: L("finance.expense"),
                    value: CurrencyFormatter.string(viewModel.monthExpense(in: currency), currency: currency),
                    systemImage: "arrow.up.circle.fill", tint: Theme.expense
                )
            }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.s) {
            quickAction(title: L("tab.finance"), systemImage: "dollarsign.circle.fill") { selectedTab = 1 }
            quickAction(title: L("tab.calendar"), systemImage: "calendar") { selectedTab = 2 }
        }
    }

    private func quickAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: systemImage).font(.title2)
                Text(title).font(Theme.Fonts.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.m)
            .background(Theme.cardBackground)
            .foregroundColor(Theme.brand)
            .cornerRadius(Theme.Radius.card)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Latest transactions

    private var latestTransactionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(L("finance.recent")) {
                Button(L("common.viewAll")) { selectedTab = 1 }
                    .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
            if viewModel.latestTransactions.isEmpty {
                FarmCard { Text(L("finance.empty")).foregroundColor(Theme.secondaryText) }
            } else {
                FarmCard {
                    ForEach(viewModel.latestTransactions) { transaction in
                        Button {
                            coordinator.navigate(to: transaction)
                            selectedTab = 1
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if transaction.id != viewModel.latestTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(L("dashboard.next7")) {
                Button(L("tab.calendar")) { selectedTab = 2 }
                    .font(Theme.Fonts.caption).foregroundColor(Theme.brand)
            }
            let activities = viewModel.upcomingActivities()
            let reminders = viewModel.upcomingReminders()
            if activities.isEmpty && reminders.isEmpty {
                FarmCard { Text(L("dashboard.noSchedule")).foregroundColor(Theme.secondaryText) }
            } else {
                FarmCard {
                    ForEach(activities) { upcomingRow(title: $0.title, date: $0.date, icon: "leaf.fill") }
                    ForEach(reminders) { upcomingRow(title: $0.title, date: $0.dueDate, icon: "bell.fill") }
                }
            }
        }
    }

    private func upcomingRow(title: String, date: Date, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon).foregroundColor(Theme.brand).frame(width: 24)
            Text(title).foregroundColor(Theme.primaryText)
            Spacer()
            Text(LocalizedDate.dayMonthString(date))
                .font(Theme.Fonts.caption).foregroundColor(Theme.secondaryText)
        }
        .padding(.vertical, 4)
    }
}
