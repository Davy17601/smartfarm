import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case income = "Income"
    case expense = "Expense"
}

struct Transaction: Identifiable, Codable {
    var id: UUID
    var title: String
    var amount: Double
    var type: TransactionType
    var category: String
    var currency: String
    var date: Date
    var note: String

    init(id: UUID = UUID(), title: String, amount: Double, type: TransactionType,
         category: String = "Other", currency: String = "KHR",
         date: Date = Date(), note: String = "") {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.currency = currency
        self.date = date
        self.note = note
    }
}
