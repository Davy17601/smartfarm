import SwiftUI
import CoreData

/// The bottom-tab-bar's 4 destinations. `AppEnvironment.selectedTab` holds
/// which one is active, shared app-wide via `.environmentObject` — so any
/// screen (e.g. the Calendar tab's bell icon, or a Home grid tile) can switch
/// tabs directly instead of pushing a duplicate page.
enum AppTab: Int, CaseIterable {
    case home
    case calendar
    case notifications
    case settings
}

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

    /// The tab bar's current selection — `MainTabView` binds its `CustomTabBar`
    /// and the Home tab to this, and other screens (the Calendar tab's bell)
    /// write to it directly to switch tabs with the same animation.
    @Published var selectedTab: AppTab = .home

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
        DashboardViewModel(activityRepository: activityRepository,
                           reminderRepository: reminderRepository)
    }

    func makeBackupService() -> BackupService {
        BackupService(transactionRepository: transactionRepository,
                      activityRepository: activityRepository,
                      reminderRepository: reminderRepository)
    }
}
