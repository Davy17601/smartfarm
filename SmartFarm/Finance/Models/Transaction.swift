import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case income = "Income"
    case expense = "Expense"

    /// Localized label shown in the UI.
    var displayName: String {
        switch self {
        case .income:  return L("type.income")
        case .expense: return L("type.expense")
        }
    }
}

/// Spending / earning categories relevant to small farms.
enum TransactionCategory: String, CaseIterable, Codable {
    case seeds      = "Seeds"
    case fertilizer = "Fertilizer"
    case labor      = "Labor"
    case tools      = "Tools"
    case sales      = "Sales"
    case other      = "Other"

    var displayName: String {
        switch self {
        case .seeds:      return L("category.seeds")
        case .fertilizer: return L("category.fertilizer")
        case .labor:      return L("category.labor")
        case .tools:      return L("category.tools")
        case .sales:      return L("category.sales")
        case .other:      return L("category.other")
        }
    }

    var systemImage: String {
        switch self {
        case .seeds:      return "leaf.fill"
        case .fertilizer: return "drop.fill"
        case .labor:      return "person.2.fill"
        case .tools:      return "hammer.fill"
        case .sales:      return "cart.fill"
        case .other:      return "tag.fill"
        }
    }
}

/// Cambodia uses both Riel and US Dollar in everyday transactions.
enum Currency: String, CaseIterable, Codable {
    case khr = "KHR"
    case usd = "USD"

    var symbol: String {
        switch self {
        case .khr: return "៛"
        case .usd: return "$"
        }
    }

    var displayName: String {
        switch self {
        case .khr: return L("currency.khr")
        case .usd: return L("currency.usd")
        }
    }
}

struct Transaction: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var currency: Currency
    var date: Date
    var note: String

    init(id: UUID = UUID(), title: String, amount: Double, type: TransactionType,
         category: TransactionCategory = .other, currency: Currency = .khr,
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
