//
//  DashboardView.swift
//  SmartFarm
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var monthTransactions: FetchedResults<TransactionEntity>
    @FetchRequest private var upcomingReminders: FetchedResults<ReminderEntity>
    @FetchRequest private var recentTransactions: FetchedResults<TransactionEntity>

    init() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let sevenDaysLater = calendar.date(byAdding: .day, value: 7, to: now)!

        _monthTransactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@",
                                   startOfMonth as CVarArg, startOfNextMonth as CVarArg)
        )

        _upcomingReminders = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \ReminderEntity.dueDate, ascending: true)],
            predicate: NSPredicate(format: "dueDate >= %@ AND dueDate <= %@ AND isCompleted == NO",
                                   now as CVarArg, sevenDaysLater as CVarArg)
        )

        let recentReq: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        recentReq.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        recentReq.fetchLimit = 5
        _recentTransactions = FetchRequest(fetchRequest: recentReq)
    }

    // MARK: — Computed Totals

    private var totalIncome: Double {
        monthTransactions.filter { $0.type == "Income" }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        monthTransactions.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
    }

    private var profit: Double { totalIncome - totalExpense }

    // MARK: — Body

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(red: 0.9, green: 0.97, blue: 0.9)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroView

                        // Cards overlap hero bottom edge
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                SummaryCardView(
                                    icon: "arrow.down.circle.fill",
                                    label: "ចំណូល",
                                    amount: Formatters.currency(totalIncome, currency: "KHR"),
                                    color: .green
                                )
                                SummaryCardView(
                                    icon: "arrow.up.circle.fill",
                                    label: "ចំណាយ",
                                    amount: Formatters.currency(totalExpense, currency: "KHR"),
                                    color: .red
                                )
                            }
                            SummaryCardView(
                                icon: "chart.line.uptrend.xyaxis",
                                label: "ចំណេញ",
                                amount: (profit >= 0 ? "+" : "") + Formatters.currency(abs(profit), currency: "KHR"),
                                color: profit >= 0 ? .blue : .red
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, -50)

                        remindersSection
                            .padding(.top, 24)

                        transactionsSection
                            .padding(.top, 24)

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: — Hero Banner

    private var heroView: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.60, blue: 0.30),
                    Color(red: 0.15, green: 0.45, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("សួស្ដី! Farm របស់អ្នក 🌾")
                    .font(.title2).bold()
                    .foregroundColor(.white)
                Text(Formatters.date(Date()))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 64)
        }
        .frame(height: 210)
    }

    // MARK: — Reminders Section

    private var remindersSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "ការរំឭកខាងមុខ", hasItems: !upcomingReminders.isEmpty)

            if upcomingReminders.isEmpty {
                emptyState(icon: "calendar.badge.clock", message: "គ្មានការរំឭកក្នុង 7 ថ្ងៃខាងមុខ")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(upcomingReminders.prefix(5).enumerated()), id: \.element.objectID) { index, reminder in
                        reminderRow(reminder)
                        if index < min(upcomingReminders.count, 5) - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.07), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: — Transactions Section

    private var transactionsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "ប្រតិបត្តិការចុងក្រោយ", hasItems: !recentTransactions.isEmpty)

            if recentTransactions.isEmpty {
                emptyState(icon: "tray", message: "គ្មានប្រតិបត្តិការ")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentTransactions.prefix(5).enumerated()), id: \.element.objectID) { index, entity in
                        transactionRow(entity)
                        if index < min(recentTransactions.count, 5) - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.07), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: — Row Components

    private func reminderRow(_ reminder: ReminderEntity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.orange)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title ?? "")
                    .font(.subheadline).fontWeight(.medium)
                Text(Formatters.shortDate(reminder.dueDate ?? Date()))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            urgencyBadge(for: reminder.dueDate ?? Date())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func transactionRow(_ entity: TransactionEntity) -> some View {
        let isIncome = entity.type == "Income"
        let sign = isIncome ? "+" : "-"
        let curr = entity.currency ?? "KHR"
        return HStack(spacing: 12) {
            Circle()
                .fill(isIncome ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(entity.title ?? "")
                    .font(.subheadline).fontWeight(.medium)
                Text(entity.category ?? "")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(sign + Formatters.currency(entity.amount, currency: curr))
                    .font(.subheadline).bold()
                    .foregroundColor(isIncome ? .green : .red)
                Text(Formatters.shortDate(entity.date ?? Date()))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: — Helper Views

    private func sectionHeader(title: String, hasItems: Bool) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            if hasItems {
                Text("មើលទាំងអស់")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
    }

    private func urgencyBadge(for date: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let isTomorrow = calendar.isDateInTomorrow(date)
        let label = isToday ? "ថ្ងៃនេះ" : (isTomorrow ? "ស្អែក" : Formatters.shortDate(date))
        let color: Color = isToday ? .red : (isTomorrow ? .orange : .gray)
        return Text(label)
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(Color.secondary.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.07), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
