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

    init(repository: TransactionRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: FinanceViewModel(repository: repository))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header
                transactionList
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L("tab.finance"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
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
        .padding(Theme.Spacing.m)
    }

    private var summaryRow: some View {
        let currency = settings.displayCurrency
        return VStack(spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                SummaryCardView(
                    title: L("finance.income"),
                    value: CurrencyFormatter.string(viewModel.totalIncome(in: currency), currency: currency),
                    systemImage: "arrow.down.circle.fill", tint: Theme.income
                )
                SummaryCardView(
                    title: L("finance.expense"),
                    value: CurrencyFormatter.string(viewModel.totalExpense(in: currency), currency: currency),
                    systemImage: "arrow.up.circle.fill", tint: Theme.expense
                )
            }
            let profit = viewModel.profit(in: currency)
            SummaryCardView(
                title: L("finance.profitLoss"),
                value: CurrencyFormatter.signedString(profit, currency: currency),
                systemImage: "chart.line.uptrend.xyaxis",
                tint: profit >= 0 ? Theme.income : Theme.expense
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

    private var transactionList: some View {
        List {
            if viewModel.filteredTransactions.isEmpty {
                Text(L("finance.empty"))
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredTransactions) { transaction in
                    NavigationLink(
                        destination: TransactionDetailView(viewModel: viewModel, transactionID: transaction.id),
                        tag: transaction.id,
                        selection: $coordinator.selectedTransactionID
                    ) {
                        TransactionRow(transaction: transaction)
                    }
                }
                .onDelete { viewModel.delete(at: $0) }
            }
        }
        .listStyle(PlainListStyle())
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
