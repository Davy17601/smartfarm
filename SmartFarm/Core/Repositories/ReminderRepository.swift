import Foundation
import CoreData

// MARK: - Protocol

protocol ReminderRepositoryProtocol {
    func fetchAll() -> [Reminder]
    func add(_ reminder: Reminder)
    func update(_ reminder: Reminder)
    func delete(id: UUID)
}

// MARK: - CoreData implementation

final class CoreDataReminderRepository: ReminderRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() -> [Reminder] {
        let request = ReminderEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReminderEntity.dueDate, ascending: true)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap(Reminder.init(entity:))
    }

    func add(_ reminder: Reminder) {
        let entity = ReminderEntity(context: context)
        entity.apply(reminder)
        saveContext()
    }

    func update(_ reminder: Reminder) {
        guard let entity = entity(for: reminder.id) else { return }
        entity.apply(reminder)
        saveContext()
    }

    func delete(id: UUID) {
        guard let entity = entity(for: id) else { return }
        context.delete(entity)
        saveContext()
    }

    // MARK: Helpers

    private func entity(for id: UUID) -> ReminderEntity? {
        let request = ReminderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save reminder: \(error)")
        }
    }
}

// MARK: - Mapping

extension Reminder {
    init?(entity: ReminderEntity) {
        guard let id = entity.id,
              let title = entity.title,
              let dueDate = entity.dueDate else { return nil }
        self.init(
            id: id,
            title: title,
            dueDate: dueDate,
            note: entity.note ?? "",
            isCompleted: entity.isCompleted,
            repeatType: RepeatType(rawValue: entity.repeatType ?? "") ?? .none
        )
    }
}

extension ReminderEntity {
    func apply(_ reminder: Reminder) {
        id = reminder.id
        title = reminder.title
        dueDate = reminder.dueDate
        note = reminder.note
        isCompleted = reminder.isCompleted
        repeatType = reminder.repeatType.rawValue
    }
}
