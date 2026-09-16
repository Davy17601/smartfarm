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

    // MARK: - Custom Finance Colors (matching Dashboard)
    /// Darker, more saturated colors for better contrast
    private let dashboardGreen = Color(red: 0.13, green: 0.55, blue: 0.13)
    private let darkerRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let darkerBlue = Color(red: 0.1, green: 0.3, blue: 0.7)

    init(repository: TransactionRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: FinanceViewModel(repository: repository))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    transactionListContent
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L("tab.finance"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { coordinator.backToDashboard() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.brand)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(dashboardGreen)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditTransactionView(mode: .add) { viewModel.add($0) }
            }
            .onAppear { viewModel.reload() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header (summary + filters)

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            summaryRow
            searchBar
            typeFilter
            categoryChips
        }
        .padding(.top, Theme.Spacing.s)
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.m)
    }

    private var summaryRow: some View {
        let currency = settings.displayCurrency
        let profit = viewModel.profit(in: currency)
        return HStack(spacing: Theme.Spacing.s) {
            FinanceSummaryCard(
                title: L("finance.income"),
                value: CurrencyFormatter.string(viewModel.totalIncome(in: currency), currency: currency),
                systemImage: "arrow.down.circle.fill", tint: dashboardGreen
            )
            FinanceSummaryCard(
                title: L("finance.expense"),
                value: CurrencyFormatter.string(viewModel.totalExpense(in: currency), currency: currency),
                systemImage: "arrow.up.circle.fill", tint: darkerRed
            )
            FinanceSummaryCard(
                title: L("finance.profitLoss"),
                value: CurrencyFormatter.signedString(profit, currency: currency),
                systemImage: "chart.line.uptrend.xyaxis",
                tint: profit >= 0 ? darkerBlue : darkerRed
            )
        }
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

    private var typeFilter: some View {
        Picker("", selection: $viewModel.filter) {
            ForEach(TransactionFilter.allCases) { Text($0.displayName).tag($0) }
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                chip(title: L("common.all"), isOn: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(TransactionCategory.allCases, id: \.self) { category in
                    chip(title: category.displayName, isOn: viewModel.selectedCategory == category) {
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
