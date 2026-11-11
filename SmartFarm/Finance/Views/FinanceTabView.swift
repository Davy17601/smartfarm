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
    @State private var showingMonthPicker = false
    @State private var showingMonthResult = false
    @State private var selectedMonth = Date() // Track currently selected month
    @State private var tempSelectedMonth = Date()
    @State private var displayedYear: Int = Calendar.current.component(.year, from: Date())

    // MARK: - Custom Finance Colors
    // Page background (same as Settings, Dashboard, Reports)
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7

    // Banner gradient colors (dark green)
    private let bannerGreenDark = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32 (top)
    private let bannerGreenLight = Color(red: 0.11, green: 0.37, blue: 0.13) // #1B5E20 (bottom)
    private let bannerButtonBg = Color.white.opacity(0.2) // Semi-transparent white for buttons

    // Summary card background colors (light soft tones)
    private let incomeCardBg = Color(red: 0.89, green: 0.95, blue: 0.88) // #E3F2E1 (light green)
    private let expenseCardBg = Color(red: 0.99, green: 0.91, blue: 0.91) // #FDE8E8 (light red/pink)
    private let profitCardBg = Color(red: 0.89, green: 0.95, blue: 0.88) // #E3F2E1 (light green)

    // Summary card icon badge colors (medium colored circles with white icons)
    private let incomeBadgeGreen = Color(red: 0.26, green: 0.63, blue: 0.28) // #43A047 (medium green circle)
    private let expenseBadgeRed = Color(red: 0.90, green: 0.22, blue: 0.21) // #E53935 (medium red circle)
    private let profitBadgeGreen = Color(red: 0.26, green: 0.63, blue: 0.28) // #43A047 (medium green circle)

    // Icon colors (white icons on colored circles)
    private let incomeIconColor = Color.white
    private let expenseIconColor = Color.white
    private let profitIconColor = Color.white

    // Summary card text colors (dark text on light backgrounds)
    private let incomeTitleGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let incomeAmountGreen = Color(red: 0.11, green: 0.37, blue: 0.13) // #1B5E20
    private let expenseTitleRed = Color(red: 0.78, green: 0.16, blue: 0.16) // #C62828
    private let expenseAmountRed = Color(red: 0.72, green: 0.11, blue: 0.11) // #B71C1C
    private let profitTitleGreen = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32
    private let profitAmountGreen = Color(red: 0.11, green: 0.37, blue: 0.13) // #1B5E20

    // Summary card border colors (light soft borders)
    private let incomeBorder = Color(red: 0.65, green: 0.84, blue: 0.65) // #A5D6A7 (light green)
    private let expenseBorder = Color(red: 0.96, green: 0.72, blue: 0.69) // #F5B7B1 (light red/pink)
    private let profitBorder = Color(red: 0.65, green: 0.84, blue: 0.65) // #A5D6A7 (light green)

    // Percent pill colors (light tinted capsules)
    private let percentGreenBg = Color(red: 0.78, green: 0.90, blue: 0.79) // #C8E6C9 (light green)
    private let percentGreenText = Color(red: 0.18, green: 0.49, blue: 0.20) // #2E7D32 (dark green)
    private let percentRedBg = Color(red: 1.0, green: 0.80, blue: 0.82) // #FFCDD2 (light red)
    private let percentRedText = Color(red: 0.78, green: 0.16, blue: 0.16) // #C62828 (dark red)

    // Pill tab colors
    private let selectedPillGreen = Color(red: 0.26, green: 0.63, blue: 0.28) // #43A047 (medium green)
    private let unselectedPillGray = Color(red: 0.22, green: 0.26, blue: 0.32) // #374151
    private let lightGrayBackground = Color(red: 0.95, green: 0.95, blue: 0.96)

    // Date header colors (darker than page so it stands out)
    private let dateHeaderBackground = Color(red: 0.835, green: 0.910, blue: 0.831) // #D5E8D4
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
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedMonth = newDate
            }
        }
    }

    private func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedMonth = newDate
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Page background (light green)
                pageBackground.ignoresSafeArea()

                // Main ScrollView with everything inside
                ScrollView {
                    VStack(spacing: 0) {
                        // Scrollable banner (extends up and stretches on overscroll)
                        scrollableBanner

                        // White content card
                        whiteContentCard
                    }
                    .padding(.bottom, 100) // Extra padding to prevent tab bar overlap
                }
                .ignoresSafeArea(edges: .top)

                // Month picker overlay
                if showingMonthPicker {
                    monthPickerOverlay
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                AddEditTransactionView(mode: .add, initialType: .expense) { viewModel.add($0) }
                    .environmentObject(settings)
            }
            .fullScreenCover(isPresented: $showingMonthResult) {
                MonthResultScreen(
                    isPresented: $showingMonthResult,
                    selectedMonth: selectedMonth,
                    transactions: viewModel.transactions,
                    currency: settings.displayCurrency
                )
                .environmentObject(settings)
            }
            .onAppear {
                viewModel.reload()
                tempSelectedMonth = selectedMonth
                displayedYear = Calendar.current.component(.year, from: selectedMonth)
            }
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
        .padding(.bottom, 20) // Green space below search bar
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            // LEFT: Back button
            Button(action: { coordinator.backToDashboard() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(bannerButtonBg)
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
                    .background(bannerButtonBg)
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

    // MARK: - Content Area

    private var whiteContentCard: some View {
        VStack(spacing: 10) {
            // Three summary cards
            summaryCardsRow
                .padding(.top, 16) // Clear gap from banner

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
                iconColor: incomeIconColor,
                badgeColor: incomeBadgeGreen,
                labelColor: incomeTitleGreen,
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
                iconColor: expenseIconColor,
                badgeColor: expenseBadgeRed,
                labelColor: expenseTitleRed,
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
                labelColor: profitTitleGreen,
                label: L("finance.profit"),
                amount: CurrencyFormatter.string(profit, currency: currency),
                amountColor: profitAmountGreen,
                percentChange: profitPercent
            )
        }
        .padding(.horizontal, Theme.Spacing.m)
    }

    private func profitSummaryCard(
        labelColor: Color,
        label: String,
        amount: String,
        amountColor: Color,
        percentChange: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Custom stacked coins icon badge (medium green circle with white coins)
            ZStack {
                Circle()
                    .fill(profitBadgeGreen)
                    .frame(width: 44, height: 44)

                // Stacked coins using three ellipses
                VStack(spacing: -4) {
                    Ellipse()
                        .fill(profitIconColor)
                        .frame(width: 16, height: 6)
                        .overlay(
                            Ellipse()
                                .stroke(profitIconColor.opacity(0.6), lineWidth: 1)
                        )

                    Ellipse()
                        .fill(profitIconColor)
                        .frame(width: 16, height: 6)
                        .overlay(
                            Ellipse()
                                .stroke(profitIconColor.opacity(0.6), lineWidth: 1)
                        )

                    Ellipse()
                        .fill(profitIconColor)
                        .frame(width: 16, height: 6)
                        .overlay(
                            Ellipse()
                                .stroke(profitIconColor.opacity(0.6), lineWidth: 1)
                        )
                }
            }

            // Label (dark green text on light background)
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Amount (dark green bold text on light background)
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
        iconColor: Color,
        badgeColor: Color,
        labelColor: Color,
        label: String,
        amount: String,
        amountColor: Color,
        backgroundColor: Color,
        borderColor: Color,
        percentChange: Double?,
        isExpense: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Icon badge (colored circle with white icon)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(badgeColor)
                .clipShape(Circle())

            // Label (dark text on light background)
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Amount (dark bold text on light background)
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
        HStack(spacing: 8) {
            // Type filter tabs
            HStack(spacing: 4) {
                ForEach(TransactionFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.filter = filter
                        }
                    }) {
                        Text(filter.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(viewModel.filter == filter ? .white : darkText)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(viewModel.filter == filter ? selectedPillGreen : Color.white)
                            .cornerRadius(17)
                    }
                }
            }
            .padding(3)
            .background(Color.white)
            .cornerRadius(17)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

            // Calendar button
            Button(action: {
                tempSelectedMonth = selectedMonth
                displayedYear = Calendar.current.component(.year, from: selectedMonth)
                withAnimation(.easeInOut(duration: 0.28)) {
                    showingMonthPicker = true
                }
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.26, green: 0.63, blue: 0.28)) // #43A047 (medium green)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
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
        .background(Color.white)
        .cornerRadius(Theme.Radius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                .background(isOn ? Theme.brand : Color.white)
                .foregroundColor(isOn ? .white : darkText)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(isOn ? 0 : 0.05), radius: isOn ? 0 : 2, x: 0, y: isOn ? 0 : 1)
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

    // MARK: - Month Picker Overlay

    private var monthPickerOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Dim background
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            showingMonthPicker = false
                        }
                    }

                // Bottom panel
                VStack(spacing: 0) {
                    Spacer()

                    ScrollView {
                        VStack(spacing: 0) {
                            // Handle bar
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 40, height: 5)
                                .padding(.top, 12)
                                .padding(.bottom, 12)

                            // Header row
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.28)) {
                                        showingMonthPicker = false
                                    }
                                }) {
                                    Text("បោះបង់")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.20)) // #2E7D32
                                }

                                Spacer()

                                Text("ជ្រើសរើសខែ")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(darkText)

                                Spacer()

                                // Invisible spacer for centering
                                Text("បោះបង់")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.clear)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)

                            // Year selector
                            yearSelector
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                            // Month grid
                            monthGrid
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                            // "ខែនេះ" button
                            Button(action: { jumpToCurrentMonth() }) {
                                Text("ខែនេះ")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(red: 0.26, green: 0.63, blue: 0.28)) // #43A047
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(red: 0.26, green: 0.63, blue: 0.28), lineWidth: 1.5)
                                    )
                                    .cornerRadius(14)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)

                            // "យល់ព្រម" button
                            Button(action: { applyMonthSelection() }) {
                                Text("យល់ព្រម")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(bannerGreenDark)
                                    .cornerRadius(14)
                            }
                            .disabled(isFutureMonth(tempSelectedMonth))
                            .opacity(isFutureMonth(tempSelectedMonth) ? 0.5 : 1.0)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)

                            // Caption
                            Text("● ចំណុចបៃតង = ខែដែលមានប្រតិបត្តិការ ចុចលើខែណាមួយ បញ្ជីនឹងបង្ហាញតែខែនេះ")
                                .font(.system(size: 13))
                                .foregroundColor(grayText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(28, corners: [.topLeft, .topRight])
                    .frame(maxHeight: geometry.size.height - geometry.safeAreaInsets.top - 80)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 49 + 12)
                }
            }
            .transition(.move(edge: .bottom))
        }
    }

    private var yearSelector: some View {
        let yearRange = getYearRange()

        return HStack {
            Button(action: {
                if yearRange.contains(displayedYear - 1) {
                    displayedYear -= 1
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }
            .disabled(!yearRange.contains(displayedYear - 1))
            .opacity(yearRange.contains(displayedYear - 1) ? 1 : 0.3)

            Spacer()

            Text(formatYear(displayedYear))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(darkText)

            Spacer()

            Button(action: {
                if yearRange.contains(displayedYear + 1) {
                    displayedYear += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(darkText)
                    .frame(width: 40, height: 40)
            }
            .disabled(!yearRange.contains(displayedYear + 1))
            .opacity(yearRange.contains(displayedYear + 1) ? 1 : 0.3)
        }
    }

    private var monthGrid: some View {
        let khmerMonths = [
            "មករា", "កុម្ភៈ", "មីនា", "មេសា", "ឧសភា", "មិថុនា",
            "កក្កដា", "សីហា", "កញ្ញា", "តុលា", "វិច្ឆិកា", "ធ្នូ"
        ]

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 10) {
            ForEach(0..<12, id: \.self) { monthIndex in
                monthButton(for: monthIndex, monthName: khmerMonths[monthIndex])
            }
        }
    }

    private func monthButton(for monthIndex: Int, monthName: String) -> some View {
        let calendar = Calendar.current
        let components = DateComponents(year: displayedYear, month: monthIndex + 1, day: 1)
        guard let monthDate = calendar.date(from: components) else {
            return AnyView(EmptyView())
        }

        let tempComp = calendar.dateComponents([.year, .month], from: tempSelectedMonth)
        let monthComp = calendar.dateComponents([.year, .month], from: monthDate)
        let isSelected = tempComp.year == monthComp.year && tempComp.month == monthComp.month
        let isFuture = isFutureMonth(monthDate)
        let hasTransactions = monthHasTransactions(monthDate)

        return AnyView(
            Button(action: {
                if !isFuture {
                    tempSelectedMonth = monthDate
                }
            }) {
                VStack(spacing: 6) {
                    Text(monthName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : darkText)

                    // Transaction indicator dot
                    if hasTransactions {
                        Circle()
                            .fill(isSelected ? Color.white : Color(red: 0.26, green: 0.63, blue: 0.28)) // #43A047
                            .frame(width: 6, height: 6)
                    } else {
                        Color.clear.frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.11, green: 0.42, blue: 0.18), // #2E7D32
                                Color(red: 0.26, green: 0.63, blue: 0.28)  // #43A047
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.95, green: 0.95, blue: 0.95), // #F1F3F2
                                Color(red: 0.95, green: 0.95, blue: 0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .cornerRadius(14)
                .opacity(isFuture ? 0.35 : 1.0)
            }
            .disabled(isFuture)
        )
    }

    private func getYearRange() -> ClosedRange<Int> {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        let oldestYear: Int
        if let oldestTransaction = viewModel.transactions.min(by: { $0.date < $1.date }) {
            oldestYear = calendar.component(.year, from: oldestTransaction.date)
        } else {
            oldestYear = currentYear - 2
        }

        return min(oldestYear, currentYear - 2)...currentYear
    }

    private func formatYear(_ year: Int) -> String {
        if LocalizationManager.shared.language == .khmer {
            let arabicToKhmer: [Character: Character] = [
                "0": "០", "1": "១", "2": "២", "3": "៣", "4": "៤",
                "5": "៥", "6": "៦", "7": "៧", "8": "៨", "9": "៩"
            ]
            return String("\(year)".map { arabicToKhmer[$0] ?? $0 })
        }
        return "\(year)"
    }

    private func isFutureMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let dateComp = calendar.dateComponents([.year, .month], from: date)
        let nowComp = calendar.dateComponents([.year, .month], from: now)

        guard let dateYear = dateComp.year, let dateMonth = dateComp.month,
              let nowYear = nowComp.year, let nowMonth = nowComp.month else {
            return false
        }

        if dateYear > nowYear {
            return true
        } else if dateYear == nowYear && dateMonth > nowMonth {
            return true
        }
        return false
    }

    private func monthHasTransactions(_ monthDate: Date) -> Bool {
        let calendar = Calendar.current
        return viewModel.transactions.contains { transaction in
            calendar.isDate(transaction.date, equalTo: monthDate, toGranularity: .month)
        }
    }

    private func jumpToCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        tempSelectedMonth = now
        displayedYear = calendar.component(.year, from: now)
    }

    private func applyMonthSelection() {
        selectedMonth = tempSelectedMonth
        withAnimation(.easeInOut(duration: 0.28)) {
            showingMonthPicker = false
        }

        // Small delay before showing result screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingMonthResult = true
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
