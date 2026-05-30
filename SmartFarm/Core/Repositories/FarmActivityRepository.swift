import Foundation
import CoreData

// MARK: - Protocol

protocol FarmActivityRepositoryProtocol {
    func fetchAll() -> [FarmActivity]
    func add(_ activity: FarmActivity)
    func update(_ activity: FarmActivity)
    func delete(id: UUID)
}

// MARK: - CoreData implementation

final class CoreDataFarmActivityRepository: FarmActivityRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() -> [FarmActivity] {
        let request = FarmActivityEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FarmActivityEntity.date, ascending: true)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap(FarmActivity.init(entity:))
    }

    func add(_ activity: FarmActivity) {
        let entity = FarmActivityEntity(context: context)
        entity.apply(activity)
        saveContext()
    }

    func update(_ activity: FarmActivity) {
        guard let entity = entity(for: activity.id) else { return }
        entity.apply(activity)
        saveContext()
    }

    func delete(id: UUID) {
        guard let entity = entity(for: id) else { return }
        context.delete(entity)
        saveContext()
    }

    // MARK: Helpers

    private func entity(for id: UUID) -> FarmActivityEntity? {
        let request = FarmActivityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save activity: \(error)")
        }
    }
}

// MARK: - Mapping

extension FarmActivity {
    init?(entity: FarmActivityEntity) {
        guard let id = entity.id,
              let title = entity.title,
              let date = entity.date else { return nil }
        self.init(
            id: id,
            title: title,
            date: date,
            note: entity.note ?? "",
            isCompleted: entity.isCompleted
        )
    }
}

extension FarmActivityEntity {
    func apply(_ activity: FarmActivity) {
        id = activity.id
        title = activity.title
        date = activity.date
        note = activity.note
        isCompleted = activity.isCompleted
    }
}
