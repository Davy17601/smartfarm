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
    var date: Date
    var note: String

    init(id: UUID = UUID(), title: String, amount: Double, type: TransactionType,
         date: Date = Date(), note: String = "") {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
    }
}
