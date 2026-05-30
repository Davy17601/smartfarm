//
//  Persistence.swift
//  SmartFarm
//
//  Created by Davy on 7/5/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let t = TransactionEntity(context: viewContext)
        t.id = UUID()
        t.title = "លក់ស្រូវ"
        t.amount = 1_500_000
        t.type = "Income"
        t.date = Date()
        let a = FarmActivityEntity(context: viewContext)
        a.id = UUID()
        a.title = "ស្រោចទឹក"
        a.date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        a.isCompleted = false
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SmartFarm")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    /// Inserts sample data on first launch only (when the store is empty).
    /// Replaces the old in-memory `FarmManager.seedSampleData`.
    func seedIfEmpty() {
        let context = container.viewContext
        let request = TransactionEntity.fetchRequest()
        request.fetchLimit = 1
        let isEmpty = ((try? context.count(for: request)) ?? 0) == 0
        guard isEmpty else { return }

        let now = Date()
        let cal = Calendar.current

        let income = TransactionEntity(context: context)
        income.apply(Transaction(title: "លក់ស្រូវ", amount: 1_500_000, type: .income,
                                  category: .sales, currency: .khr, date: now))
        let expense = TransactionEntity(context: context)
        expense.apply(Transaction(title: "ទិញជី", amount: 200_000, type: .expense,
                                   category: .fertilizer, currency: .khr, date: now))

        let water = FarmActivityEntity(context: context)
        water.apply(FarmActivity(title: "ស្រោចទឹក",
                                 date: cal.date(byAdding: .day, value: 1, to: now) ?? now))
        let fertilize = FarmActivityEntity(context: context)
        fertilize.apply(FarmActivity(title: "បូកជី",
                                     date: cal.date(byAdding: .day, value: 3, to: now) ?? now))

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed sample data: \(error)")
        }
    }
}
