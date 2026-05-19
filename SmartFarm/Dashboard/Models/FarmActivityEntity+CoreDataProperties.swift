import Foundation
import CoreData

extension FarmActivityEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FarmActivityEntity> {
        return NSFetchRequest<FarmActivityEntity>(entityName: "FarmActivityEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var isCompleted: Bool

}

extension FarmActivityEntity: Identifiable {}
