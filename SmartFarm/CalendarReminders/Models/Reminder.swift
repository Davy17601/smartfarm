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
    /// When this reminder was marked done — set when `isCompleted` turns
    /// `true`, cleared when undone. Backed by a new optional Core Data
    /// attribute, lightweight-migrated like `FarmActivity.completedAt`; a
    /// missing key in old backup JSON decodes to `nil` automatically since
    /// this is an `Optional` property on a synthesized `Codable`.
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, dueDate: Date = Date(),
         note: String = "", isCompleted: Bool = false, repeatType: RepeatType = .none,
         completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.note = note
        self.isCompleted = isCompleted
        self.repeatType = repeatType
        self.completedAt = completedAt
    }
}
