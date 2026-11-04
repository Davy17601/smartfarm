//
//  MonthResultScreen.swift
//  SmartFarm
//

import SwiftUI

enum MonthResultFilter: String, CaseIterable, Identifiable {
    case all = "សរុប"
    case income = "ចំណូល"
    case expense = "ចំណាយ"

    var id: String { rawValue }
}

struct MonthResultScreen: View {
    @Binding var isPresented: Bool
    let selectedMonth: Date
    let transactions: [Transaction]
    let currency: Currency

    @State private var filter: MonthResultFilter = .all

    // Colors
    private let pageBackground = Color(red: 0.92, green: 0.96, blue: 0.91) // #EAF4E7
    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let brandGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let selectedGreen = Color(red: 0.26, green: 0.63, blue: 0.28) // #43A047
    private let incomeGreen = Color(red: 0.08, green: 0.50, blue: 0.24) // #15803D
    private let expenseRed = Color(red: 0.73, green: 0.11, blue: 0.11) // #B91C1C
    private let darkGray = Color(red: 0.12, green: 0.16, blue: 0.22) // #1F2937
    private let grayText = Color(red: 0.29, green: 0.34, blue: 0.39) // #4B5563
    private let dateHeaderBg = Color(red: 0.835, green: 0.910, blue: 0.831) // #D5E8D4

    // Khmer month names
    private let khmerMonths = [
        "មករា", "កុម្ភៈ", "មីនា", "មេសា", "ឧសភា", "មិថុនា",
        "កក្កដា", "សីហា", "កញ្ញា", "តុលា", "វិច្ឆិកា", "ធ្នូ"
    ]

    private var monthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var filteredTransactions: [Transaction] {
        switch filter {
        case .all:
            return monthTransactions
        case .income:
            return monthTransactions.filter { $0.type == .income }
        case .expense:
            return monthTransactions.filter { $0.type == .expense }
        }
    }

    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        return grouped.map { (date: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == .income && $0.currency == currency }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        monthTransactions.filter { $0.type == .expense && $0.currency == currency }
            .reduce(0) { $0 + $1.amount }
    }

    private var profit: Double {
        totalIncome - totalExpense
    }

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 50)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Filter buttons
                filterButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary card
                        summaryCard
                            .padding(.horizontal, 16)

                        // Transaction list
                        transactionList
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(brandGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }

            Spacer()

            Text("ខែ \(formattedMonthYear)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(primaryText)

            Spacer()

            // Invisible spacer to center title
            Color.clear.frame(width: 40, height: 40)
        }
    }

    private var filterButtons: some View {
        HStack(spacing: 8) {
            ForEach(MonthResultFilter.allCases) { filterOption in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        filter = filterOption
                    }
                }) {
                    Text(filterOption.rawValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(filter == filterOption ? .white : primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(filter == filterOption ? brandGreen : Color.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(filter == filterOption ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            if filter == .all {
                // All: show income, expense, profit
                HStack(spacing: 12) {
                    summaryItem(label: "ចំណូល", amount: totalIncome, color: incomeGreen)
                    summaryItem(label: "ចំណាយ", amount: totalExpense, color: expenseRed)
                    summaryItem(label: "ប្រាក់ចំណេញ", amount: profit, color: darkGray)
                }
            } else if filter == .income {
                // Income only
                VStack(spacing: 8) {
                    Text(CurrencyFormatter.string(totalIncome, currency: currency))
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundColor(incomeGreen)
                    Text("\(filteredTransactions.count) ប្រតិបត្តិការ")
                        .font(.system(size: 14))
                        .foregroundColor(grayText)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            } else {
                // Expense only
                VStack(spacing: 8) {
                    Text(CurrencyFormatter.string(totalExpense, currency: currency))
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundColor(expenseRed)
                    Text("\(filteredTransactions.count) ប្រតិបត្តិការ")
                        .font(.system(size: 14))
                        .foregroundColor(grayText)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
        }
    }

    private func summaryItem(label: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(grayText)
            Text(CurrencyFormatter.string(amount, currency: currency))
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var transactionList: some View {
        Group {
            if filteredTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(grayText.opacity(0.5))
                    Text("មិនមានប្រតិបត្តិការក្នុងខែនេះ")
                        .font(.system(size: 16))
                        .foregroundColor(grayText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                VStack(spacing: 12) {
                    ForEach(groupedTransactions, id: \.date) { group in
                        VStack(spacing: 0) {
                            // Date header
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(primaryText)
                                Text(formattedDateHeader(group.date))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(primaryText)
                                Spacer()
                            }
                            .padding(10)
                            .background(dateHeaderBg)
                            .cornerRadius(12)

                            // Transactions
                            VStack(spacing: 0) {
                                ForEach(Array(group.transactions.enumerated()), id: \.element.id) { index, transaction in
                                    TransactionRow(transaction: transaction)
                                        .padding(.horizontal, 12)

                                    if index < group.transactions.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 12)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                        }
                    }
                }
            }
        }
    }

    private var formattedMonthYear: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)

        let monthName = khmerMonths[month - 1]

        if LocalizationManager.shared.language == .khmer {
            let arabicToKhmer: [Character: Character] = [
                "0": "០", "1": "១", "2": "២", "3": "៣", "4": "៤",
                "5": "៥", "6": "៦", "7": "៧", "8": "៨", "9": "៩"
            ]
            let yearKhmer = String("\(year)".map { arabicToKhmer[$0] ?? $0 })
            return "\(monthName) \(yearKhmer)"
        } else {
            return "\(monthName) \(year)"
        }
    }

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
}
