import Foundation

enum RepeatType: String, CaseIterable, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

struct Reminder: Identifiable, Codable {
    var id: UUID
    var title: String
    var dueDate: Date
    var note: String
    var isCompleted: Bool
    var repeatType: RepeatType

    init(id: UUID = UUID(), title: String, dueDate: Date = Date(),
         note: String = "", isCompleted: Bool = false, repeatType: RepeatType = .none) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.note = note
        self.isCompleted = isCompleted
        self.repeatType = repeatType
    }
}
