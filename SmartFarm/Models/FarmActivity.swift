import Foundation

struct FarmActivity: Identifiable, Codable {
    var id: UUID
    var title: String
    var date: Date
    var note: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, date: Date = Date(),
         note: String = "", isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.date = date
        self.note = note
        self.isCompleted = isCompleted
    }
}
