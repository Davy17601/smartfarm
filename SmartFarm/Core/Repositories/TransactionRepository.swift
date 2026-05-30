import Foundation
import CoreData

// MARK: - Protocol

/// Abstracts persistence for transactions so ViewModels never touch CoreData.
/// A mock conforming to this protocol makes ViewModels unit-testable.
protocol TransactionRepositoryProtocol {
    func fetchAll() -> [Transaction]
    func add(_ transaction: Transaction)
    func update(_ transaction: Transaction)
    func delete(id: UUID)
}

// MARK: - CoreData implementation

final class CoreDataTransactionRepository: TransactionRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() -> [Transaction] {
        let request = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap(Transaction.init(entity:))
    }

    func add(_ transaction: Transaction) {
        let entity = TransactionEntity(context: context)
        entity.apply(transaction)
        saveContext()
    }

    func update(_ transaction: Transaction) {
        guard let entity = entity(for: transaction.id) else { return }
        entity.apply(transaction)
        saveContext()
    }

    func delete(id: UUID) {
        guard let entity = entity(for: id) else { return }
        context.delete(entity)
        saveContext()
    }

    // MARK: Helpers

    private func entity(for id: UUID) -> TransactionEntity? {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save transaction: \(error)")
        }
    }
}

// MARK: - Mapping (the single place entity <-> struct conversion lives)

extension Transaction {
    init?(entity: TransactionEntity) {
        guard let id = entity.id,
              let title = entity.title,
              let typeRaw = entity.type, let type = TransactionType(rawValue: typeRaw),
              let date = entity.date else { return nil }
        self.init(
            id: id,
            title: title,
            amount: entity.amount,
            type: type,
            category: TransactionCategory(rawValue: entity.category ?? "") ?? .other,
            currency: Currency(rawValue: entity.currency ?? "") ?? .khr,
            date: date,
            note: entity.note ?? ""
        )
    }
}

extension TransactionEntity {
    func apply(_ transaction: Transaction) {
        id = transaction.id
        title = transaction.title
        amount = transaction.amount
        type = transaction.type.rawValue
        category = transaction.category.rawValue
        currency = transaction.currency.rawValue
        date = transaction.date
        note = transaction.note
    }
}
