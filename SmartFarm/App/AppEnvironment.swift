import SwiftUI
import CoreData

/// Dependency-injection container for the whole app.
///
/// Owns the `PersistenceController` and exposes the repositories that feature
/// ViewModels depend on. Created once in `SmartFarmApp` and injected into the
/// view hierarchy via `.environmentObject`. ViewModels are built through the
/// `make…ViewModel()` factory methods so views never wire up dependencies by hand.
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceController

    let transactionRepository: TransactionRepositoryProtocol
    let activityRepository: FarmActivityRepositoryProtocol
    let reminderRepository: ReminderRepositoryProtocol

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let context = persistence.container.viewContext
        self.transactionRepository = CoreDataTransactionRepository(context: context)
        self.activityRepository = CoreDataFarmActivityRepository(context: context)
        self.reminderRepository = CoreDataReminderRepository(context: context)
        persistence.seedIfEmpty()
    }

    // MARK: - ViewModel factories
    // (Feature ViewModels are added here as each module is built.)

    func makeFinanceViewModel() -> FinanceViewModel {
        FinanceViewModel(repository: transactionRepository)
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(activityRepository: activityRepository,
                          reminderRepository: reminderRepository)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(transactionRepository: transactionRepository,
                           activityRepository: activityRepository,
                           reminderRepository: reminderRepository)
    }

    func makeBackupService() -> BackupService {
        BackupService(transactionRepository: transactionRepository,
                      activityRepository: activityRepository,
                      reminderRepository: reminderRepository)
    }
}
