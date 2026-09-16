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

        // Income transactions (3-4 this month)
        let income1 = TransactionEntity(context: context)
        income1.apply(Transaction(title: "លក់ស្រូវ", amount: 1_500_000, type: .income,
                                  category: .sales, currency: .khr,
                                  date: cal.date(byAdding: .day, value: -5, to: now) ?? now))

        let income2 = TransactionEntity(context: context)
        income2.apply(Transaction(title: "លក់បន្លែ", amount: 600_000, type: .income,
                                  category: .sales, currency: .khr,
                                  date: cal.date(byAdding: .day, value: -3, to: now) ?? now))

        let income3 = TransactionEntity(context: context)
        income3.apply(Transaction(title: "លក់ផ្លែឈើ", amount: 350_000, type: .income,
                                  category: .sales, currency: .khr,
                                  date: cal.date(byAdding: .day, value: -1, to: now) ?? now))

        // Expense transactions (3-4 this month)
        let expense1 = TransactionEntity(context: context)
        expense1.apply(Transaction(title: "ទិញជី", amount: 200_000, type: .expense,
                                   category: .fertilizer, currency: .khr,
                                   date: cal.date(byAdding: .day, value: -6, to: now) ?? now))

        let expense2 = TransactionEntity(context: context)
        expense2.apply(Transaction(title: "ថ្នាំសម្លាប់សត្វល្អិត", amount: 150_000, type: .expense,
                                   category: .other, currency: .khr,
                                   date: cal.date(byAdding: .day, value: -4, to: now) ?? now))

        let expense3 = TransactionEntity(context: context)
        expense3.apply(Transaction(title: "គ្រាប់ពូជ", amount: 180_000, type: .expense,
                                   category: .seeds, currency: .khr,
                                   date: cal.date(byAdding: .day, value: -2, to: now) ?? now))

        let expense4 = TransactionEntity(context: context)
        expense4.apply(Transaction(title: "ជួលកម្លាំងពលកម្ម", amount: 250_000, type: .expense,
                                   category: .labor, currency: .khr, date: now))

        // Reminders (2-3 upcoming in next 7 days) with realistic farming times
        let reminder1 = ReminderEntity(context: context)
        // Watering at 6:00 AM (early morning)
        var wateringDate = cal.date(byAdding: .day, value: 1, to: now) ?? now
        wateringDate = cal.date(bySettingHour: 6, minute: 0, second: 0, of: wateringDate) ?? wateringDate
        reminder1.apply(Reminder(title: "ស្រោចទឹក",
                                 dueDate: wateringDate,
                                 note: "ដើមបន្លែនៅក្បែរផ្ទះ"))

        let reminder2 = ReminderEntity(context: context)
        reminder2.apply(Reminder(title: "ប្រមូលផល",
                                 dueDate: cal.date(byAdding: .day, value: 5, to: now) ?? now,
                                 note: "ប្រមូលបន្លែពេលព្រឹក"))

        let reminder3 = ReminderEntity(context: context)
        // Fertilizing at 7:00 AM (mid-morning, avoid midday heat)
        var fertilizingDate = cal.date(byAdding: .day, value: 3, to: now) ?? now
        fertilizingDate = cal.date(bySettingHour: 7, minute: 0, second: 0, of: fertilizingDate) ?? fertilizingDate
        reminder3.apply(Reminder(title: "បាចជី",
                                 dueDate: fertilizingDate,
                                 note: "ជីសរីរាង្គសម្រាប់ដំណាំថ្មី"))

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed sample data: \(error)")
        }
    }
}
