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

    // MARK: - Custom Finance Colors
    // Banner gradient colors
    private let bannerGreenDark = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let bannerGreenLight = Color(red: 0.18, green: 0.62, blue: 0.27) // #2E9E44
    private let addButtonGreen = Color(red: 0.08, green: 0.32, blue: 0.18) // #14532D

    // Summary card background colors
    private let incomeCardBg = Color(red: 0.85, green: 0.94, blue: 0.87) // #D8F0DD
    private let expenseCardBg = Color(red: 0.98, green: 0.85, blue: 0.85) // #FBD9D9
    private let profitCardBg = Color(red: 0.85, green: 0.92, blue: 0.89) // #D9EBE4

    // Summary card badge colors
    private let incomeBadgeGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let expenseBadgeRed = Color(red: 0.86, green: 0.15, blue: 0.15) // #DC2626
    private let profitBadgeGreen = Color(red: 0.18, green: 0.55, blue: 0.34) // #2E8B57

    // Summary card amount colors
    private let incomeAmountGreen = Color(red: 0.09, green: 0.40, blue: 0.20) // #166534
    private let expenseAmountRed = Color(red: 0.86, green: 0.15, blue: 0.15) // #DC2626
    private let profitAmountDark = Color(red: 0.12, green: 0.16, blue: 0.22) // #1F2937

    // Summary card border colors
    private let incomeBorder = Color(red: 0.11, green: 0.42, blue: 0.18).opacity(0.35) // #1B6B2F
    private let expenseBorder = Color(red: 0.86, green: 0.15, blue: 0.15).opacity(0.35) // #DC2626
    private let profitBorder = Color(red: 0.18, green: 0.55, blue: 0.34).opacity(0.35) // #2E8B57

    // Percent pill colors
    private let percentGreenBg = Color(red: 0.73, green: 0.97, blue: 0.82) // #BBF7D0
    private let percentGreenText = Color(red: 0.09, green: 0.40, blue: 0.20) // #166534
    private let percentRedBg = Color(red: 0.99, green: 0.79, blue: 0.79) // #FECACA
    private let percentRedText = Color(red: 0.73, green: 0.11, blue: 0.11) // #B91C1C

    // Pill tab colors
    private let selectedPillGreen = Color(red: 0.18, green: 0.62, blue: 0.27) // #2E9E44
    private let unselectedPillGray = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let lightGrayBackground = Color(red: 0.95, green: 0.95, blue: 0.96)

    // Date header colors
    private let dateHeaderBackground = Color(red: 0.91, green: 0.94, blue: 0.92) // #E8F0EC
    private let darkText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let grayText = Color(red: 0.29, green: 0.34, blue: 0.39) // #4B5563
    private let grayDark = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let placeholderGray = Color(red: 0.42, green: 0.45, blue: 0.50) // #6B7280

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

    /// Formats date header as "ថ្ងៃ {day} {month name} {year}" in Khmer or appropriate format in English
    private func formattedDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)

        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale

        if LocalizationManager.shared.language == .khmer {
            formatter.setLocalizedDateFormatFromTemplate("MMMM")
            let monthName = formatter.string(from: date)
            let arabicToKhmer: [Character: Character] = [
                "0": "០", "1": "១", "2": "២", "3": "៣", "4": "៤",
                "5": "៥", "6": "៦", "7": "៧", "8": "៨", "9": "៩"
            ]
            let dayKhmer = String("\(day)".map { arabicToKhmer[$0] ?? $0 })
            let yearKhmer = String("\(year)".map { arabicToKhmer[$0] ?? $0 })
            return "ថ្ងៃ \(dayKhmer) \(monthName) \(yearKhmer)"
        } else {
            formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
            return formatter.string(from: date)
        }
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
            ZStack(alignment: .top) {
                // Background
                Theme.background.ignoresSafeArea()

                // Main ScrollView with everything inside
                ScrollView {
                    VStack(spacing: 0) {
                        // Scrollable banner (extends up and stretches on overscroll)
                        scrollableBanner

                        // White content card that overlaps banner
                        whiteContentCard
                            .offset(y: -12) // Slight overlap
                    }
                    .padding(.bottom, 100) // Extra padding to prevent tab bar overlap
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                AddEditTransactionView(mode: .add, initialType: .expense) { viewModel.add($0) }
                    .environmentObject(settings)
            }
            .onAppear { viewModel.reload() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Scrollable Banner

    private var scrollableBanner: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let height: CGFloat = 160 // Reduced banner height
            let stretchHeight = max(height, height + offset)

            ZStack(alignment: .topTrailing) {
                // Gradient background that extends up and stretches on overscroll
                LinearGradient(
                    gradient: Gradient(colors: [bannerGreenDark, bannerGreenLight]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width, height: stretchHeight)
                .offset(y: offset > 0 ? -offset : 0)
                .cornerRadius(28, corners: [.bottomLeft, .bottomRight])

                // Decorative elements on the right
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 100, height: 100)
                        .offset(x: 40, y: 10)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 70, height: 70)
                        .offset(x: 50, y: 50)

                    Circle()
                        .fill(bannerGreenLight.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .offset(x: 20, y: 80)
                }
                .offset(y: offset > 0 ? -offset : 0)
            }
        }
        .frame(height: 160)
        .overlay(
            // Banner content (header + search)
            bannerContent
                .padding(.top, 50) // Account for status bar
        )
    }

    private var bannerContent: some View {
        VStack(spacing: 8) {
            // Header row
            headerRow

            // Search bar
            searchBarCompact
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12) // Reduced from 16
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            // LEFT: Back button
            Button(action: { coordinator.backToDashboard() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            // Icon circle
            ZStack {
                // Wallet icon as base
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(bannerGreenDark)
                    .offset(y: 2)

                // Leaf on top
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(bannerGreenDark)
                    .offset(x: -6, y: -6)
            }
            .frame(width: 56, height: 56)
            .background(Color.white)
            .clipShape(Circle())

            // Title + Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(L("tab.finance"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(L("finance.subtitle"))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            // Add button
            Button(action: { showingAdd = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(addButtonGreen)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var searchBarCompact: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(bannerGreenDark)
            TextField(L("finance.search"), text: $viewModel.searchText)
                .font(.system(size: 14))
                .foregroundColor(darkText)
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(grayText)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - White Content Card

    private var whiteContentCard: some View {
        VStack(spacing: 10) {
            // Three summary cards
            summaryCardsRow
                .padding(.top, Theme.Spacing.m)

            // Existing filter tabs
            pillTabSelector
                .padding(.horizontal, Theme.Spacing.m)

            // Month selector
            monthSelector
                .padding(.horizontal, Theme.Spacing.m)

            // Category chips
            categoryChips
                .padding(.horizontal, Theme.Spacing.m)

            // Transaction list
            transactionListContent
        }
        .padding(.bottom, Theme.Spacing.m)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Theme.Spacing.m)
    }

    // MARK: - Summary Cards Row

    private var summaryCardsRow: some View {
        let currency = settings.displayCurrency
        let income = viewModel.monthIncome(for: selectedMonth, in: currency)
        let expense = viewModel.monthExpense(for: selectedMonth, in: currency)
        let profit = viewModel.monthProfit(for: selectedMonth, in: currency)

        let incomePercent = viewModel.incomePercentChange(for: selectedMonth, in: currency)
        let expensePercent = viewModel.expensePercentChange(for: selectedMonth, in: currency)
        let profitPercent = viewModel.profitPercentChange(for: selectedMonth, in: currency)

        return HStack(spacing: 10) {
            // Income card
            summaryCard(
                icon: "leaf.fill",
                badgeColor: incomeBadgeGreen,
                label: L("finance.totalIncome"),
                amount: CurrencyFormatter.string(income, currency: currency),
                amountColor: incomeAmountGreen,
                backgroundColor: incomeCardBg,
                borderColor: incomeBorder,
                percentChange: incomePercent,
                isExpense: false
            )

            // Expense card
            summaryCard(
                icon: "wallet.pass.fill",
                badgeColor: expenseBadgeRed,
                label: L("finance.totalExpense"),
                amount: CurrencyFormatter.string(expense, currency: currency),
                amountColor: expenseAmountRed,
                backgroundColor: expenseCardBg,
                borderColor: expenseBorder,
                percentChange: expensePercent,
                isExpense: true
            )

            // Profit card with custom stacked coins icon
            profitSummaryCard(
                label: L("finance.profit"),
                amount: CurrencyFormatter.string(profit, currency: currency),
                amountColor: profit >= 0 ? profitAmountDark : expenseAmountRed,
                percentChange: profitPercent
            )
        }
        .padding(.horizontal, Theme.Spacing.m)
    }

    private func profitSummaryCard(
        label: String,
        amount: String,
        amountColor: Color,
        percentChange: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Custom stacked coins icon badge
            ZStack {
                Circle()
                    .fill(profitBadgeGreen)
                    .frame(width: 44, height: 44)

                // Stacked coins using three ellipses
                VStack(spacing: -4) {
                    Ellipse()
                        .fill(Color.white)
                        .frame(width: 16, height: 6)
                        .overlay(
                            Ellipse()
                                .stroke(Color(red: 0.11, green: 0.42, blue: 0.18), lineWidth: 1)
                        )

                    Ellipse()
                        .fill(Color.white)
                        .frame(width: 16, height: 6)
                        .overlay(
                            Ellipse()
                                .stroke(Color(red: 0.11, green: 0.42, blue: 0.18), lineWidth: 1)
                        )

                    Ellipse()
                        .fill(Color.white)
                        .frame(width: 16, height: 6)
                        .overlay(
                            Ellipse()
                                .stroke(Color(red: 0.11, green: 0.42, blue: 0.18), lineWidth: 1)
                        )
                }
            }

            // Label
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(grayDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Amount
            Text(amount)
                .font(.system(size: 20, weight: .bold).monospacedDigit())
                .foregroundColor(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Bottom row: percent pill + "ពីមុន"
            if let percent = percentChange {
                HStack(spacing: 4) {
                    percentPill(percent: percent, isExpense: false)
                    Spacer()
                    Text(L("finance.previous"))
                        .font(.system(size: 11))
                        .foregroundColor(grayText)
                }
            } else {
                HStack {
                    Spacer()
                }
                .frame(height: 20) // Maintain consistent height
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(profitCardBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(profitBorder, lineWidth: 1)
        )
    }

    private func summaryCard(
        icon: String,
        badgeColor: Color,
        label: String,
        amount: String,
        amountColor: Color,
        backgroundColor: Color,
        borderColor: Color,
        percentChange: Double?,
        isExpense: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Icon badge
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(badgeColor)
                .clipShape(Circle())

            // Label
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(grayDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Amount
            Text(amount)
                .font(.system(size: 20, weight: .bold).monospacedDigit())
                .foregroundColor(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Bottom row: percent pill + "ពីមុន"
            if let percent = percentChange {
                HStack(spacing: 4) {
                    percentPill(percent: percent, isExpense: isExpense)
                    Spacer()
                    Text(L("finance.previous"))
                        .font(.system(size: 11))
                        .foregroundColor(grayText)
                }
            } else {
                HStack {
                    Spacer()
                }
                .frame(height: 20) // Maintain consistent height
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func percentPill(percent: Double, isExpense: Bool) -> some View {
        let isPositive = percent >= 0
        // For expense: up is bad (red), down is good (green)
        // For income/profit: up is good (green), down is bad (red)
        let isGood = isExpense ? !isPositive : isPositive

        let bgColor = isGood ? percentGreenBg : percentRedBg
        let textColor = isGood ? percentGreenText : percentRedText
        let arrow = isPositive ? "↑" : "↓"

        return HStack(spacing: 2) {
            Text("\(arrow) \(abs(percent), specifier: "%.0f")%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(bgColor)
        .cornerRadius(10)
    }

    // MARK: - Pill-shaped Tab Selector

    private var pillTabSelector: some View {
        HStack(spacing: 4) {
            ForEach(TransactionFilter.allCases) { filter in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.filter = filter
                    }
                }) {
                    Text(filter.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.filter == filter ? .white : darkText)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(viewModel.filter == filter ? selectedPillGreen : Color(red: 0.93, green: 0.95, blue: 0.96)) // #EEF3F5
                        .cornerRadius(17)
                }
            }
        }
        .padding(3)
        .background(Color(red: 0.93, green: 0.95, blue: 0.96))
        .cornerRadius(17)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button(action: { goToPreviousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(darkText)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(darkText)

                Text(formattedMonthYear(selectedMonth))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(darkText)
            }

            Spacer()

            Button(action: { goToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(darkText)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.Radius.card)
    }


    private var categoryChips: some View {
        let uniqueCategories = Array(Set(viewModel.transactions.map { $0.category }))
            .filter { !$0.isEmpty }
            .sorted()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: L("common.all"), isOn: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(uniqueCategories, id: \.self) { category in
                    chip(title: TransactionCategory.localizedName(for: category), isOn: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                    }
                }
            }
        }
    }

    private func chip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(isOn ? Theme.brand : Theme.cardBackground)
                .foregroundColor(isOn ? .white : darkText)
                .cornerRadius(15)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - List

    private var transactionListContent: some View {
        VStack(spacing: 10) {
            if viewModel.filteredTransactions.isEmpty {
                VStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(grayText.opacity(0.5))
                    Text(L("finance.empty"))
                        .font(.system(size: 16))
                        .foregroundColor(grayText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xl)
            } else {
                ForEach(viewModel.groupedTransactions, id: \.date) { group in
                    VStack(spacing: 0) {
                        // Date header card
                        HStack(spacing: Theme.Spacing.s) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(darkText)
                            Text(formattedDateHeader(group.date))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(darkText)
                            Spacer()
                        }
                        .padding(Theme.Spacing.s)
                        .background(dateHeaderBackground)
                        .cornerRadius(Theme.Radius.button)

                        // Transactions for this day in a white card
                        VStack(spacing: 0) {
                            ForEach(Array(group.transactions.enumerated()), id: \.element.id) { index, transaction in
                                NavigationLink(
                                    destination: TransactionDetailView(viewModel: viewModel, transactionID: transaction.id),
                                    tag: transaction.id,
                                    selection: $coordinator.selectedTransactionID
                                ) {
                                    TransactionRow(transaction: transaction)
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if index < group.transactions.count - 1 {
                                    Divider()
                                        .padding(.horizontal, Theme.Spacing.m)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(Theme.Radius.card)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, Theme.Spacing.m)
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
