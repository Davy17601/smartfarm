//
//  CoreDataManager.swift
//  SmartFarm
//

import CoreData

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }

    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
}
