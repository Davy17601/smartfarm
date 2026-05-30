import Foundation

/// Codable snapshot of all user data.
struct BackupData: Codable {
    var transactions: [Transaction]
    var activities: [FarmActivity]
    var reminders: [Reminder]
}

/// Exports all records to JSON and restores them. The domain structs are already
/// `Codable`, so the whole backup is a single JSON document.
final class BackupService {
    private let transactionRepository: TransactionRepositoryProtocol
    private let activityRepository: FarmActivityRepositoryProtocol
    private let reminderRepository: ReminderRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol,
         activityRepository: FarmActivityRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.activityRepository = activityRepository
        self.reminderRepository = reminderRepository
    }

    // MARK: - Export

    func exportFile() -> URL? {
        let snapshot = BackupData(
            transactions: transactionRepository.fetchAll(),
            activities: activityRepository.fetchAll(),
            reminders: reminderRepository.fetchAll()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(snapshot) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SmartFarm-Backup.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            assertionFailure("Failed to write backup: \(error)")
            return nil
        }
    }

    // MARK: - Restore

    /// Restores from a JSON backup. Existing records with matching ids are
    /// overwritten (upsert), so restoring is idempotent.
    @discardableResult
    func restore(from url: URL) -> Bool {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(BackupData.self, from: data) else { return false }

        for t in snapshot.transactions {
            transactionRepository.delete(id: t.id)
            transactionRepository.add(t)
        }
        for a in snapshot.activities {
            activityRepository.delete(id: a.id)
            activityRepository.add(a)
        }
        for r in snapshot.reminders {
            reminderRepository.delete(id: r.id)
            reminderRepository.add(r)
        }
        return true
    }
}
