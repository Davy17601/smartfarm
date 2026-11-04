//
//  MonthPickerSheet.swift
//  SmartFarm
//

import SwiftUI

/// Month picker sheet with year navigation and 3-column month grid
struct MonthPickerSheet: View {
    @Binding var selectedMonth: Date
    @Binding var isPresented: Bool
    let transactions: [Transaction]

    @State private var tempSelectedMonth: Date
    @State private var displayedYear: Int

    // Colors
    private let primaryText = Color(red: 0.07, green: 0.09, blue: 0.15) // #111827
    private let brandGreen = Color(red: 0.11, green: 0.42, blue: 0.18) // #1B6B2F
    private let borderGreen = Color(red: 0.81, green: 0.89, blue: 0.81) // #CFE3CF

    // Khmer month names
    private let khmerMonths = [
        "មករា", "កុម្ភៈ", "មីនា", "មេសា", "ឧសភា", "មិថុនា",
        "កក្កដា", "សីហា", "កញ្ញា", "តុលា", "វិច្ឆិកា", "ធ្នូ"
    ]

    init(selectedMonth: Binding<Date>, isPresented: Binding<Bool>, transactions: [Transaction]) {
        self._selectedMonth = selectedMonth
        self._isPresented = isPresented
        self.transactions = transactions

        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth.wrappedValue)
        self._tempSelectedMonth = State(initialValue: selectedMonth.wrappedValue)
        self._displayedYear = State(initialValue: year)
    }

    private var yearRange: ClosedRange<Int> {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // Find oldest transaction year, or use 2 years back as minimum
        let oldestYear: Int
        if let oldestTransaction = transactions.min(by: { $0.date < $1.date }) {
            oldestYear = calendar.component(.year, from: oldestTransaction.date)
        } else {
            oldestYear = currentYear - 2
        }

        return min(oldestYear, currentYear - 2)...currentYear
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            HStack {
                Text("ជ្រើសរើសខែ")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryText)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryText)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            // Year selector
            HStack {
                Button(action: { goToPreviousYear() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(brandGreen)
                        .frame(width: 40, height: 40)
                }
                .disabled(!yearRange.contains(displayedYear - 1))
                .opacity(yearRange.contains(displayedYear - 1) ? 1 : 0.3)

                Spacer()

                Text("\(displayedYear)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(brandGreen)

                Spacer()

                Button(action: { goToNextYear() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(brandGreen)
                        .frame(width: 40, height: 40)
                }
                .disabled(!yearRange.contains(displayedYear + 1))
                .opacity(yearRange.contains(displayedYear + 1) ? 1 : 0.3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            // Month grid (3 columns x 4 rows)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(0..<12, id: \.self) { monthIndex in
                    monthButton(for: monthIndex)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            // Action buttons
            HStack(spacing: 12) {
                // "ខែនេះ" button (This Month)
                Button(action: { jumpToCurrentMonth() }) {
                    Text("ខែនេះ")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(brandGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(brandGreen, lineWidth: 2)
                        )
                        .cornerRadius(14)
                }

                // "យល់ព្រម" button (Confirm)
                Button(action: { applySelection() }) {
                    Text("យល់ព្រម")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(brandGreen)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }

    private func monthButton(for monthIndex: Int) -> some View {
        let calendar = Calendar.current
        let components = DateComponents(year: displayedYear, month: monthIndex + 1, day: 1)
        guard let monthDate = calendar.date(from: components) else {
            return AnyView(EmptyView())
        }

        let isSelected = calendar.isDate(tempSelectedMonth, equalTo: monthDate, toGranularity: .month)
        let isCurrent = calendar.isDate(Date(), equalTo: monthDate, toGranularity: .month)
        let isFuture = monthDate > Date()
        let hasTransactions = monthHasTransactions(monthDate)

        let tempSelectedComp = calendar.dateComponents([.year, .month], from: tempSelectedMonth)
        let monthComp = calendar.dateComponents([.year, .month], from: monthDate)
        let isTempSelected = tempSelectedComp.year == monthComp.year && tempSelectedComp.month == monthComp.month

        return AnyView(
            Button(action: {
                if !isFuture {
                    tempSelectedMonth = monthDate
                }
            }) {
                VStack(spacing: 4) {
                    Text(khmerMonths[monthIndex])
                        .font(.system(size: 15, weight: isTempSelected ? .bold : .semibold))
                        .foregroundColor(isTempSelected ? .white : primaryText)

                    // Indicator dots
                    HStack(spacing: 4) {
                        // Current month dot (green)
                        if isCurrent {
                            Circle()
                                .fill(isTempSelected ? Color.white : brandGreen)
                                .frame(width: 4, height: 4)
                        }

                        // Has transactions dot (gray if not selected, white if selected)
                        if hasTransactions && !isCurrent {
                            Circle()
                                .fill(isTempSelected ? Color.white.opacity(0.7) : Color.gray.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isTempSelected ? brandGreen : Color.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isTempSelected ? Color.clear : borderGreen, lineWidth: 1)
                )
                .opacity(isFuture ? 0.35 : 1.0)
            }
            .disabled(isFuture)
        )
    }

    private func monthHasTransactions(_ monthDate: Date) -> Bool {
        let calendar = Calendar.current
        return transactions.contains { transaction in
            calendar.isDate(transaction.date, equalTo: monthDate, toGranularity: .month)
        }
    }

    private func goToPreviousYear() {
        if yearRange.contains(displayedYear - 1) {
            displayedYear -= 1
        }
    }

    private func goToNextYear() {
        if yearRange.contains(displayedYear + 1) {
            displayedYear += 1
        }
    }

    private func jumpToCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        tempSelectedMonth = now
        displayedYear = calendar.component(.year, from: now)
    }

    private func applySelection() {
        selectedMonth = tempSelectedMonth
        isPresented = false
    }
}
