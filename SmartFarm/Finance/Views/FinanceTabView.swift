//
//  FinanceTabView.swift
//  SmartFarm
//

import SwiftUI

struct FinanceTabView: View {
    @EnvironmentObject private var coordinator: FinanceCoordinator
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel: FinanceViewModel
    @State private var showingAdd = false
    @State private var selectedMonth = Date() // Track currently selected month

    // MARK: - Custom Finance Colors (matching Dashboard)
    /// Darker, more saturated colors for better contrast
    private let dashboardGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let darkerRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let darkerBlue = Color(red: 0.1, green: 0.3, blue: 0.7)

    init(repository: TransactionRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: FinanceViewModel(repository: repository))
    }

    // MARK: - Month Navigation Helpers

    /// Formats the selected month/year for display in Khmer or English
    private func formattedMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        let dateString = formatter.string(from: date)

        // Convert to Khmer numerals if in Khmer locale
        if LocalizationManager.shared.language == .khmer {
            let arabicToKhmer: [Character: Character] = [
                "0": "០", "1": "១", "2": "២", "3": "៣", "4": "៤",
                "5": "៥", "6": "៦", "7": "៧", "8": "៨", "9": "៩"
            ]
            return String(dateString.map { arabicToKhmer[$0] ?? $0 })
        }
        return dateString
    }

    private func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    customHeader
                    header
                    transactionListContent
                }
                .padding(.bottom, 100) // Extra padding to prevent tab bar overlap
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                AddEditTransactionView(mode: .add, initialType: .expense) { viewModel.add($0) }
                    .environmentObject(settings)
            }
            .onAppear { viewModel.reload() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Custom Header with Back Button, Title, and Add Button

    private var customHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Top row: Back button on left, add button on right
            HStack {
                Button(action: { coordinator.backToDashboard() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                        .frame(width: 36, height: 36)
                }

                Spacer()

                // Add transaction button
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(dashboardGreen)
                        .clipShape(Circle())
                }
            }

            // Bottom row: Wallet icon + title
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(dashboardGreen)
                    .clipShape(Circle())

                Text(L("tab.finance"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.primaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, Theme.Spacing.m)
    }

    // MARK: - Header (summary + filters)

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            pillTabSelector
            monthSelector
            summaryRow
            searchBar
            categoryChips
        }
        .padding(.top, Theme.Spacing.s)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.m)
    }

    // MARK: - Pill-shaped Tab Selector

    private var pillTabSelector: some View {
        HStack(spacing: 4) {
            ForEach(TransactionFilter.allCases) { filter in
                Button(action: { viewModel.filter = filter }) {
                    Text(filter.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.filter == filter ? .white : Theme.primaryText)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .frame(maxWidth: .infinity)
                        .background(viewModel.filter == filter ? dashboardGreen : Color.clear)
                        .cornerRadius(20)
                }
            }
        }
        .padding(4)
        .background(Theme.cardBackground)
        .cornerRadius(24)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button(action: { goToPreviousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
            }

            Spacer()

            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.primaryText)

                Text(formattedMonthYear(selectedMonth))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
            }

            Spacer()

            Button(action: { goToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryText)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.Radius.card)
    }

    // MARK: - Single Unified Financial Summary Banner

    private var summaryRow: some View {
        let currency = settings.displayCurrency
        let income = viewModel.monthIncome(for: selectedMonth, in: currency)
        let expense = viewModel.monthExpense(for: selectedMonth, in: currency)
        let profit = viewModel.monthProfit(for: selectedMonth, in: currency)

        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            // Title
            Text(L("finance.summary"))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(dashboardGreen)

            // Three items in horizontal row with dividers
            HStack(spacing: 0) {
                summaryBannerItem(
                    icon: "arrow.up",
                    label: L("finance.income"),
                    amount: CurrencyFormatter.string(income, currency: currency),
                    color: dashboardGreen
                )

                // Vertical divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 60)
                    .padding(.horizontal, Theme.Spacing.m)

                summaryBannerItem(
                    icon: "arrow.down",
                    label: L("finance.expense"),
                    amount: CurrencyFormatter.string(expense, currency: currency),
                    color: darkerRed
                )

                // Vertical divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 60)
                    .padding(.horizontal, Theme.Spacing.m)

                summaryBannerItem(
                    icon: "leaf.fill",
                    label: L("finance.profit"),
                    amount: CurrencyFormatter.string(profit, currency: currency),
                    color: dashboardGreen
                )
            }
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(Theme.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(dashboardGreen, lineWidth: 2)
        )
    }

    /// Individual item within the summary banner (icon, label, amount)
    private func summaryBannerItem(icon: String, label: String, amount: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            // Circular icon badge with colored background
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())

            // Label text
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Amount
            Text(amount)
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "magnifyingglass").foregroundColor(Theme.secondaryText)
            TextField(L("finance.search"), text: $viewModel.searchText)
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.s)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.Radius.button)
    }

    private var categoryChips: some View {
        let uniqueCategories = Array(Set(viewModel.transactions.map { $0.category }))
            .filter { !$0.isEmpty }
            .sorted()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                chip(title: L("common.all"), isOn: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(uniqueCategories, id: \.self) { category in
                    chip(title: category, isOn: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                    }
                }
            }
        }
    }

    private func chip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.caption)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(isOn ? Theme.brand : Theme.cardBackground)
                .foregroundColor(isOn ? .white : Theme.primaryText)
                .cornerRadius(Theme.Radius.button)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - List

    private var transactionListContent: some View {
        VStack(spacing: 0) {
            if viewModel.filteredTransactions.isEmpty {
                Text(L("finance.empty"))
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredTransactions) { transaction in
                        NavigationLink(
                            destination: TransactionDetailView(viewModel: viewModel, transactionID: transaction.id),
                            tag: transaction.id,
                            selection: $coordinator.selectedTransactionID
                        ) {
                            TransactionRow(transaction: transaction)
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.vertical, Theme.Spacing.s)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if transaction.id != viewModel.filteredTransactions.last?.id {
                            Divider()
                                .padding(.horizontal, Theme.Spacing.m)
                        }
                    }
                }
                .background(Theme.cardBackground)
                .cornerRadius(Theme.Radius.card)
                .padding(.horizontal, Theme.Spacing.m)
            }
        }
    }
}

struct FinanceTabView_Previews: PreviewProvider {
    static var previews: some View {
        let env = AppEnvironment(persistence: .preview)
        return FinanceTabView(repository: env.transactionRepository)
            .environmentObject(FinanceCoordinator())
            .environmentObject(AppSettings.shared)
    }
}
