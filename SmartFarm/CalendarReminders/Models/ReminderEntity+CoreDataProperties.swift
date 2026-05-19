import Foundation
import CoreData

extension ReminderEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReminderEntity> {
        return NSFetchRequest<ReminderEntity>(entityName: "ReminderEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var note: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var repeatType: String?

}

extension ReminderEntity: Identifiable {}
