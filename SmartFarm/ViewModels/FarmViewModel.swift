import Foundation

class FarmViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var activities: [FarmActivity] = []
    @Published var reminders: [Reminder] = []

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var profit: Double { totalIncome - totalExpense }

    func upcomingActivities(within days: Int = 7) -> [FarmActivity] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        return activities
            .filter { !$0.isCompleted && $0.date >= now && $0.date <= future }
            .sorted { $0.date < $1.date }
    }

    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
    }

    func addActivity(_ activity: FarmActivity) {
        activities.append(activity)
    }

    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
    }

    func deleteActivity(at offsets: IndexSet) {
        activities.remove(atOffsets: offsets)
    }

    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
    }

    func deleteReminder(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
    }

    func upcomingReminders(within days: Int = 7) -> [Reminder] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        return reminders
            .filter { !$0.isCompleted && $0.dueDate >= now && $0.dueDate <= future }
            .sorted { $0.dueDate < $1.dueDate }
    }
}
